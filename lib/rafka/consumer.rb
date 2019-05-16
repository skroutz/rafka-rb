require "json"
require "securerandom"

module Rafka
  # A Rafka-backed Kafka consumer that consumes messages from a specific topic
  # and belongs to a specific consumer group. Offsets may be committed
  # automatically or manually.
  #
  # @see https://kafka.apache.org/documentation/#consumerapi
  class Consumer
    include GenericCommands

    REQUIRED_OPTS = [:group, :topic].freeze

    # @return [Redis::Client] the underlying Redis client instance
    attr_reader :redis

    # @return [String] the argument passed to BLPOP
    attr_reader :blpop_arg

    # Initialize a new consumer.
    #
    # @param [Hash] opts
    # @option opts [String] :host ("localhost") server hostname
    # @option opts [Fixnum] :port (6380) server port
    # @option opts [String] :topic Kafka topic to consume (required)
    # @option opts [String] :group Kafka consumer group name (required)
    # @option opts [String] :id (random) Kafka consumer id
    # @option opts [Boolean] :auto_commit (true) automatically commit
    #   offsets
    # @option opts [Hash] :librdkafka ({}) librdkafka configuration. It will
    #   be merged over the existing configuration set in the server.
    #   See https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md
    #   for more information
    # @option opts [Hash] :redis ({}) Configuration for the underlying Redis
    #   client. See {REDIS_DEFAULTS}
    #
    # @raise [RuntimeError] if a required option was not provided
    #   (see {REQUIRED_OPTS})
    #
    # @return [Consumer]
    def initialize(opts={})
      opts[:id] ||= SecureRandom.hex
      opts[:id] = "#{opts[:group]}:#{opts[:id]}"
      opts[:auto_commit] = true if opts[:auto_commit].nil?
      opts[:librdkafka] ||= {}

      @rafka_opts, @redis_opts = parse_opts(opts)

      # NOTE: We disable connection-level timeout since it conflicts with
      # BLPOP timeout and our rafka consumer flow.
      @redis_opts.merge!(timeout: 0)
      @redis = Redis.new(@redis_opts)

      @blpop_arg = "topics:#{@rafka_opts[:topic]}"
      @blpop_arg << ":#{opts[:librdkafka].to_json}" if !opts[:librdkafka].empty?
    end

    # Consumes the next message.
    #
    # If :auto_commit is true, offsets are committed automatically.
    # In the block form, offsets are committed only if the block executes
    # without raising any exceptions.
    #
    # If :auto_commit is false, offsets have to be committed manually using
    # {#commit}.
    #
    # @param timeout [Fixnum] the time in seconds to wait for a message. If
    #   reached, {#consume} returns nil.
    #
    # @yieldparam [Message] msg the consumed message
    #
    # @raise [MalformedMessageError] if the message cannot be parsed
    # @raise [ConsumeError] if there was a server error
    #
    # @return [nil, Message] the consumed message, or nil of there wasn't any
    #
    # @example Consume a message
    #   msg = consumer.consume
    #   msg.value # => "hi"
    #
    # @example Consume a message and commit offset if the block does not raise an exception
    #   consumer.consume { |msg| puts "I received #{msg.value}" }
    def consume(timeout=5)
      raised = false
      msg = consume_one(timeout)

      return nil if !msg

      begin
        yield(msg) if block_given?
      rescue => e
        raised = true
        raise e
      end

      msg
    ensure
      commit(msg) if @rafka_opts[:auto_commit] && msg && !raised
    end

    # Consume a batch of messages.
    #
    # Messages are accumulated in a batch until (a) batch_size number of
    # messages are accumulated or (b) batching_max_sec seconds have passed.
    # When either of the conditions is met the batch is returned.
    #
    # If :auto_commit is true, offsets are committed automatically.
    # In the block form, offsets are committed only if the block executes
    # without raising any exceptions.
    #
    # If :auto_commit is false, offsets have to be committed manually using
    # {#commit}.
    #
    # @note Either one of, or both batch_size and batching_max_sec may be
    #   provided, but not neither.
    #
    # @param timeout [Fixnum] the time in seconds to wait for each message
    # @param batch_size [Fixnum] maximum number of messages to accumulate
    #   in the batch
    # @param batching_max_sec [Fixnum] maximum time in seconds to wait for
    #   messages to accumulate in the batch
    #
    # @yieldparam [Array<Message>] msgs the batch
    #
    # @raise [MalformedMessageError] if a message cannot be parsed
    # @raise [ConsumeError] if there was a server error
    # @raise [ArgumentError] if neither batch_size nor batching_max_sec were
    #   provided
    #
    # @return [Array<Message>] the batch
    #
    # @example Consume a batch of 10 messages
    #   msgs = consumer.consume_batch(batch_size: 10)
    #   msgs.size # => 10
    #
    # @example Accumulate messages for 5 seconds and consume the batch
    #   msgs = consumer.consume_batch(batching_max_sec: 5)
    #   msgs.size # => 3813
    def consume_batch(timeout: 1.0, batch_size: 0, batching_max_sec: 0)
      if batch_size == 0 && batching_max_sec == 0
        raise ArgumentError, "one of batch_size or batching_max_sec must be greater than 0"
      end

      raised = false
      start_time = Time.now
      msgs = []

      loop do
        break if batch_size > 0 && msgs.size >= batch_size
        break if batching_max_sec > 0 && (Time.now - start_time >= batching_max_sec)
        msg = consume_one(timeout)
        msgs << msg if msg
      end

      begin
        yield(msgs) if block_given?
      rescue => e
        raised = true
        raise e
      end

      msgs
    ensure
      commit(*msgs) if @rafka_opts[:auto_commit] && !raised
    end

    # Commit offsets for the given messages.
    #
    # If more than one messages refer to the same topic/partition pair,
    # only the largest offset amongst them is committed.
    #
    # @note This is non-blocking operation; a successful server reply means
    #   offsets are received by the server and will _eventually_ be submitted
    #   to Kafka. It is not guaranteed that offsets will be actually committed
    #   in case of failures.
    #
    # @param msgs [Array<Message>] any number of messages for which to commit
    #   offsets
    #
    # @raise [ConsumeError] if there was a server error
    #
    # @return [Hash{String=>Hash{Fixnum=>Fixnum}}] the actual offsets sent
    #   to the server for commit. Keys contain topics while values contain
    #   the respective partition/offset pairs.
    def commit(*msgs)
      tp = prepare_for_commit(*msgs)

      tp.each do |topic, po|
        po.each do |partition, offset|
          Rafka.wrap_errors do
            @redis.rpush("acks", "#{topic}:#{partition}:#{offset}")
          end
        end
      end

      tp
    end

    private

    # @param opts [Hash] options hash as passed to {#initialize}
    #
    # @return [Array<Hash, Hash>] rafka opts, redis opts
    def parse_opts(opts)
      REQUIRED_OPTS.each do |opt|
        raise "#{opt.inspect} option not provided" if opts[opt].nil?
      end

      rafka_opts = opts.reject { |k| k == :redis || k == :librdkafka }

      redis_opts = REDIS_DEFAULTS.dup.merge(opts[:redis] || {})
      redis_opts.merge!(
        rafka_opts.select { |k| [:host, :port, :id].include?(k) }
      )

      [rafka_opts, redis_opts]
    end

    # Accepts one or more messages and prepare them for commit.
    #
    # @param msgs [Array<Message>]
    #
    # @return [Hash{String=>Hash{Fixnum=>Fixnum}}] the offsets to be committed.
    #   Keys denote the topics while values contain the partition=>offset pairs.
    def prepare_for_commit(*msgs)
      tp = Hash.new { |h, k| h[k] = Hash.new(0) }

      msgs.each do |msg|
        if msg.offset >= tp[msg.topic][msg.partition]
          tp[msg.topic][msg.partition] = msg.offset
        end
      end

      tp
    end

    # @param timeout [Fixnum]
    #
    # @raise [MalformedMessageError]
    #
    # @return [nil, Message]
    def consume_one(timeout)
      msg = nil

      Rafka.wrap_errors do
        # We don't use Redis#blpop directly because it ends up calling
        # Redis::Client#call_with_timeout, which automatically retries the
        # command upon ConnectionError. This is unwanted in rafka, since when
        # we get a ConnectionError (i.e. server is shutting down) we want
        # to immediately enter the retry mechanism so that we reconnect
        # to the server.
        #
        # If we instead immediately retried the command, we could end up with
        # "client id is already taken" errors, in case the
        # underlying librdkafka consumer was not yet finalized.
        msg = @redis.client.without_socket_timeout do
          @redis.client.call([:blpop, [@blpop_arg], timeout])
        end
      end

      msg = Message.new(msg) if msg
      msg
    end
  end
end

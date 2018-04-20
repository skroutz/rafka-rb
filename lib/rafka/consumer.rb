require 'securerandom'

module Rafka
  # A Kafka consumer that consumes messages from a given Kafka topic
  # and belongs to a specific consumer group. Offsets are commited
  # automatically; see {#consume} for more info.
  #
  # @see https://kafka.apache.org/documentation/#consumerapi
  class Consumer
    include GenericCommands

    REQUIRED_OPTS = [:group, :topic]

    # @return [Redis::Client] the underlying Redis client instance
    attr_reader :redis

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
    # @option opts [Hash] :redis ({}) Configuration for the
    #   underlying Redis client (see {REDIS_DEFAULTS})
    #
    # @raise [RuntimeError] if a required option was not provided
    #   (see {REQUIRED_OPTS})
    #
    # @return [Consumer]
    def initialize(opts={})
      opts[:id] ||= SecureRandom.hex
      opts[:id] = "#{opts[:group]}:#{opts[:id]}"
      opts[:auto_commit] = true if opts[:auto_commit].nil?

      @rafka_opts, @redis_opts = parse_opts(opts)
      @redis = Redis.new(@redis_opts)
      @topic = "topics:#{@rafka_opts[:topic]}"
    end

    # Consumes the next message.
    #
    # If :auto_commit is true, offsets are commited automatically.
    # In the block form, offsets are commited only if the block executes
    # without raising any exceptions.
    #
    # If :auto_commit is false, offsets have to be commited manually; see
    # {#commit}.
    #
    # @param timeout [Fixnum] the time in seconds to wait for a message. If
    #   reached, {#consume} returns nil.
    #
    # @yieldparam [Message] msg the consumed message
    #
    # @raise [MalformedMessageError] if the message cannot be parsed
    # @raise [ConsumeError] if there was any error consuming a message
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
      # redis-rb didn't automatically call `CLIENT SETNAME` until v3.2.2
      # (https://github.com/redis/redis-rb/issues/510)
      #
      # TODO(agis): get rid of this when we drop support for 3.2.1 and before
      if !@redis.client.connected? && Gem::Version.new(Redis::VERSION) < Gem::Version.new("3.2.2")
        Rafka.wrap_errors do
          @redis.client.call([:client, :setname, @redis.id])
        end
      end

      raised = false
      msg = nil
      setname_attempts = 0

      begin
        Rafka.wrap_errors do
          Rafka.with_retry(times: @redis_opts[:reconnect_attempts]) do
            msg = @redis.blpop(@topic, timeout: timeout)
          end
        end
      rescue ConsumeError => e
        # redis-rb didn't automatically call `CLIENT SETNAME` until v3.2.2
        # (https://github.com/redis/redis-rb/issues/510)
        #
        # this is in case the server restarts while we were performing a BLPOP
        #
        # TODO(agis): get rid of this when we drop support for 3.2.1 and before
        if e.message =~ /Identify yourself/ && setname_attempts < 5
          sleep 0.5
          @redis.client.call([:client, :setname, @redis.id])
          setname_attempts += 1
          retry
        end

        raise e
      end

      return if !msg

      begin
        msg = Message.new(msg)
        yield(msg) if block_given?
      rescue => e
        raised = true
        raise e
      end

      msg
    ensure
      if msg && !raised && @rafka_opts[:auto_commit]
        Rafka.wrap_errors do
          @redis.rpush("acks", "#{msg.topic}:#{msg.partition}:#{msg.offset}")
        end
      end
    end

    # Commit offsets for the given messages.
    #
    # If more than one messages refer to the same topic/partition pair,
    # only the largest offset amongst them is committed.
    #
    # @note This is non-blocking operation; a successful server reply means
    #   offsets are received by the server and will _eventually_ be committed
    #   to Kafka.
    #
    # @param msgs [Array<Message>] the messages for which to commit offsets
    #
    # @raise [ConsumeError] if there was any error commiting offsets
    #
    # @return [Hash] the actual offsets sent for commit
    # @return [Hash{String=>Hash{Integer=>Integer}}] the actual offsets sent
    #   for commit.Keys denote the topics while values contain the
    #   partition=>offset pairs.
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

      rafka_opts = opts.reject { |k| k == :redis }

      redis_opts = REDIS_DEFAULTS.dup.merge(opts[:redis] || {})
      redis_opts.merge!(
        rafka_opts.select { |k| [:host, :port, :id].include?(k) }
      )

      return rafka_opts, redis_opts
    end

    # Accepts one or more messages and prepare them for commit.
    #
    # @param msgs [Array<Message>]
    #
    # @return [Hash{String=>Hash{Integer=>Integer}}] the offsets to be commited.
    #   Keys denote the topics while values contain the partition=>offset pairs.
    def prepare_for_commit(*msgs)
      tp = Hash.new { |h, k| h[k] = Hash.new(0) }

      msgs.each do |msg|
        if msg.offset > tp[msg.topic][msg.partition]
          tp[msg.topic][msg.partition] = msg.offset
        end
      end

      tp
    end
  end
end

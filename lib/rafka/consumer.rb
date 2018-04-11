require 'securerandom'

module Rafka
  # A Kafka consumer that consumes messages from a given Kafka topic
  # and belongs to a specific consumer group. Offsets are commited
  # automatically; see {#consume} for more info.
  #
  # @see https://kafka.apache.org/documentation/#consumerapi
  class Consumer
    include GenericCommands

    REQUIRED = [:group, :topic]

    # The underlying Redis client object
    attr_reader :redis

    # Create a new consumer.
    #
    # @param [Hash] opts
    # @option opts [String] :host ("localhost") server hostname
    # @option opts [Fixnum] :port (6380) server port
    # @option opts [String] :topic Kafka topic to consume (required)
    # @option opts [String] :group Kafka consumer group name (required)
    # @option opts [String] :id (random) Kafka consumer id
    # @option opts [Hash] :redis ({}) Optional configuration for the
    #   underlying Redis client
    #
    # @return [Consumer]
    def initialize(opts={})
      @options = parse_opts(opts)
      @redis = Redis.new(@options)
      @topic = "topics:#{opts[:topic]}"
    end

    # Consumes the next message and commit offsets automatically. In the
    # block form, offsets are commited only if the block executes
    # without raising any exceptions.
    #
    # @param timeout [Fixnum] the time in seconds to wait for a message. If
    #   reached, {#consume} returns nil.
    #
    # @yieldparam [Message] the consumed message
    #
    # @raise [MalformedMessageError] if the message cannot be parsed
    #
    # @return [nil, Message]
    #
    # @example Consume a message
    #   msg = consumer.consume #=> #<Rafka::Message:0x007fda00502850 @topic="greetings", @partition=1, @offset=10, @value="hi">
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
          Rafka.with_retry(times: @options[:reconnect_attempts]) do
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
      if msg && !raised
        Rafka.wrap_errors do
          @redis.rpush("acks", "#{msg.topic}:#{msg.partition}:#{msg.offset}")
        end
      end
    end

    private

    # @return [Hash]
    def parse_opts(opts)
      REQUIRED.each do |opt|
        raise "#{opt.inspect} option not provided" if opts[opt].nil?
      end

      rafka_opts = opts.reject { |k| k == :redis }
      redis_opts = opts[:redis] || {}

      options = DEFAULTS.dup.merge(rafka_opts).merge(redis_opts)
      options[:id] = SecureRandom.hex if options[:id].nil?
      options[:id] = "#{options[:group]}:#{options[:id]}"
      options
    end
  end
end

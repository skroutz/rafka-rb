require 'securerandom'

module Rafka
  class Consumer
    include GenericCommands

    REQUIRED = [:group, :topic]

    # The underlying Redis client object
    attr_reader :redis

    # Create a new client instance.
    #
    # @param [Hash] opts
    # @option opts [String] :host ("localhost") server hostname
    # @option opts [Fixnum] :port (6380) server port
    # @option opts [String] :topic Kafka topic to consume (required)
    # @option opts [String] :group Kafka consumer group name (required)
    # @option opts [String] :id (random) Kafka consumer id
    # @option opts [Hash] :redis ({}) Optional configuration for the
    #   underlying Redis client
    def initialize(opts={})
      @options = parse_opts(opts)
      @redis = Redis.new(@options)
      @topic = "topics:#{opts[:topic]}"
    end

    # Fetches the next message. Offsets are commited automatically. In the
    # block form, the offset is commited only if the given block haven't
    # raised any exceptions.
    #
    # @param timeout [Fixnum] the time in seconds to wait for a message
    #
    # @raise [MalformedMessageError] if the message cannot be parsed
    #
    # @return [nil, Message]
    #
    # @example Consume a message
    #   puts consume(5).value
    #
    # @example Consume and commit offset if the block runs successfully
    #   consume(5) { |msg| puts "I received #{msg.value}" }
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

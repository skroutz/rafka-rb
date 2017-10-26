module Rafka
  class Producer
    include GenericCommands

    # Access the underlying Redis client object
    attr_reader :redis

    # Create a new client instance.
    #
    # @param [Hash] opts
    # @option opts [String] :host ("localhost") server hostname
    # @option opts [Fixnum] :port (6380) server port
    # @options opts [Hash] :redis Configuration options for the underlying
    #   Redis client
    #
    # @return [Producer]
    def initialize(opts={})
      @options = parse_opts(opts)
      @redis = Redis.new(@options)
    end

    # Produce a message. This is an asynchronous operation.
    #
    # @param topic [String]
    # @param msg [#to_s]
    # @param key [#to_s] two or more messages with the same key will always be
    #   assigned to the same partition.
    #
    # @example
    #   produce("greetings", "Hello there!")
    #
    # @example
    #   produce("greetings", "Hello there!", key: "hi")
    def produce(topic, msg, key: nil)
      Rafka.wrap_errors do
        Rafka.with_retry(times: @options[:reconnect_attempts]) do
          redis_key = "topics:#{topic}"
          redis_key << ":#{key}" if key
          @redis.rpushx(redis_key, msg.to_s)
        end
      end
    end

    # Flush any buffered messages. Blocks until all messages are flushed or
    # timeout exceeds.
    #
    # @param timeout_ms [Fixnum] (5000) The timeout in milliseconds
    #
    # @return [Fixnum] The number of unflushed messages
    def flush(timeout_ms=5000)
      Rafka.wrap_errors do
        @redis.dump(timeout_ms.to_s)
      end
    end

    private

    # @return [Hash]
    def parse_opts(opts)
      rafka_opts = opts.reject { |k| k == :redis }
      redis_opts = opts[:redis] || {}
      DEFAULTS.dup.merge(opts).merge(redis_opts)
    end
  end
end

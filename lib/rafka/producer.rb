module Rafka
  # A Kafka producer that can produce to different topics.
  # See {#produce} for more info.
  #
  # @see https://kafka.apache.org/documentation/#producerapi
  class Producer
    include GenericCommands

    # Access the underlying Redis client object
    attr_reader :redis

    # Create a new producer.
    #
    # @param [Hash] opts
    # @option opts [String] :host ("localhost") server hostname
    # @option opts [Fixnum] :port (6380) server port
    # @option opts [Hash] :redis Configuration options for the underlying
    #   Redis client
    #
    # @return [Producer]
    def initialize(opts={})
      @options = parse_opts(opts)
      @redis = Redis.new(@options)
    end

    # Produce a message to a topic. This is an asynchronous operation.
    #
    # @param topic [String]
    # @param msg [#to_s] the message
    # @param key [#to_s] an optional partition hashing key. Two or more messages
    #   with the same key will always be written to the same partition.
    #
    # @example Simple produce
    #   producer = Rafka::Producer.new
    #   producer.produce("greetings", "Hello there!")
    #
    # @example Produce two messages with a hashing key. Those messages are guaranteed to be written to the same partition
    #     producer = Rafka::Producer.new
    #     produce("greetings", "Aloha", key: "abc")
    #     produce("greetings", "Hola", key: "abc")
    def produce(topic, msg, key: nil)
      Rafka.wrap_errors do
        redis_key = "topics:#{topic}"
        redis_key << ":#{key}" if key
        @redis.rpushx(redis_key, msg.to_s)
      end
    end

    # Flush any buffered messages. Blocks until all messages are written or the
    # given timeout exceeds.
    #
    # @param timeout_ms [Fixnum]
    #
    # @return [Fixnum] The number of unflushed messages
    def flush(timeout_ms=5000)
      Rafka.wrap_errors do
        Integer(@redis.dump(timeout_ms.to_s))
      end
    end

    private

    # @return [Hash]
    def parse_opts(opts)
      rafka_opts = opts.reject { |k| k == :redis }
      redis_opts = opts[:redis] || {}
      REDIS_DEFAULTS.dup.merge(opts).merge(redis_opts).merge(rafka_opts)
    end
  end
end

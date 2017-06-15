require 'SecureRandom'

module Rufka
  class Consumer
    DEFAULTS = {
      host: "localhost",
      port: 6380,
      reconnect_attempts: 0,
    }

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
    # @option opts [Hash] :redis_opts ({}) Optional configuration for the
    #   underlying Redis client
    def initialize(opts = {})
      opts[:redis_opts] = {} if !opts[:redis_opts]
      opts = parse_opts(opts)
      client_id = "#{opts[:group]}:#{opts[:id]}"
      @redis = Redis.new(host: opts[:host], port: opts[:port], id: client_id)
      @topic = "topics:#{opts[:topic]}"
    end

    # Consume a message.
    #
    # @param timeout [Fixnum] The time in seconds to wait for a message
    #   (default: 5)
    #
    # @return [nil, String] The message, if any
    #
    # @example
    #   consume(5) { |msg| puts "I received #{msg}" }
    def consume(timeout=5)
      res = @redis.blpop(@topic, timeout: timeout)

      return if !res

      topic, partition, offset, res = res[1], res[3], res[5], res[-1]

      begin
        raised = false
        yield(res) if block_given?
      rescue => e
        raised = true
        raise e
      end

      res
    ensure
      if res && !raised
        @redis.rpush("acks", "#{topic}:#{partition}:#{offset}")
      end
    end

    private

    def parse_opts(opts)
      options = DEFAULTS.dup.merge(opts).merge(opts[:redis_opts])
      options[:id] = SecureRandom.hex if !options[:id]

      REQUIRED.each do |opt|
        raise "#{opt} not provided" if !options[opt]
      end

      options
    end
  end
end

require "redis"
require 'SecureRandom'

module Rufka
  class Consumer
    DEFAULTS = {
      host: "localhost",
      port: 6380
    }

    REQUIRED = [:group, :topic]

    # Provides access to the underlying Redis client
    attr_reader :redis

    # Create a new client instance.
    #
    # @param [Hash] opts
    # @option opts [String] :host ("localhost") server hostname
    # @option opts [Fixnum] :port (6380) server port
    # @option opts [String] :topic Kafka topic to consume (required)
    # @option opts [String] :group Kafka consumer group name (required)
    # @option opts [String] :id (random) Kafka consumer id
    def initialize(opts = {})
      opts = parse_opts(opts)
      client_id = "#{opts[:group]}:#{opts[:id]}"

      @redis = Redis.new(
        host: opts[:host], port: opts[:port], id: client_id, reconnect_attempts: 0
      )

      @topic = "topics:#{opts[:topic]}"
    end

    # Consumes the last message.
    #
    # @param timeout [Fixnum] The time in seconds to wait for a message
    #   (default: 5)
    #
    # @return [nil, String] The message, if any
    #
    # @example
    #   pop(5) { |msg| puts "I received #{msg}" }
    def pop(timeout=5)
      res = @redis.blpop(@topic, timeout: timeout)

      if res
        topic, partition, offset = res[1], res[3], res[5]
        res = res.last
      end

      begin
        raised = false
        yield(res) if block_given?
      rescue => e
        raised = true
        raise e
      end

      res
    ensure # TODO: do we need this?
      if res && !raised
        @redis.rpush("acks", "#{topic}:#{partition}:#{offset}")
      end
    end

    private

    def parse_opts(opts)
      options = DEFAULTS.dup.merge(opts)
      options[:port] = Integer(options[:port])
      options[:id] = SecureRandom.hex if !options[:id]

      REQUIRED.each do |opt|
        raise "#{opt} not provided" if !options[opt]
      end

      options
    end
  end
end


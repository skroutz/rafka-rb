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
    # @option opts [Hash] :redis_opts ({}) Optional configuration for the
    #   underlying Redis client
    def initialize(opts={})
      opts[:redis_opts] = {} if !opts[:redis_opts]
      opts = parse_opts(opts)
      client_id = "#{opts[:group]}:#{opts[:id]}"
      @redis = Redis.new(host: opts[:host], port: opts[:port], id: client_id)
      @topic = "topics:#{opts[:topic]}"
    end

    # Fetch the next message.
    #
    # @param timeout [Fixnum] the time in seconds to wait for a message
    #
    # @raise [MalformedMessage] if the message from Rafka cannot be parsed
    #
    # @return [nil, Message] the message, if any
    #
    # @example
    #   consume(5) { |msg| puts "I received #{msg.value}" }
    def consume(timeout=5)
      msg = @redis.blpop(@topic, timeout: timeout)

      return if !msg

      msg = Message.new(msg)

      begin
        raised = false
        yield(msg) if block_given?
      rescue => e
        raised = true
        raise e
      end

      msg
    ensure
      if msg && !raised
        @redis.rpush("acks", "#{msg.topic}:#{msg.partition}:#{msg.offset}")
      end
    end

    private

    def parse_opts(opts)
      options = DEFAULTS.dup.merge(opts).merge(opts[:redis_opts])
      options[:id] = SecureRandom.hex if !options[:id]

      REQUIRED.each do |opt|
        raise "#{opt.inspect} option not provided" if !options[opt]
      end

      options
    end
  end
end

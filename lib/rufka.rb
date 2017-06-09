require "redis"
require 'SecureRandom'

class Rufka
  DEFAULTS = {
    host: "localhost",
    port: 6380,
    timeout: 5
  }

  REQUIRED = [:consumer_group, :topic]

  # Provides access to the underlying Redis client
  attr_reader :redis

  # Create a new client instance.
  #
  # @param [Hash] opts
  # @option opts [String] :host ("localhost") server hostname
  # @option opts [Fixnum] :port (6380) server port
  # @option opts [String] :topic Kafka topic to consume (required)
  # @option opts [String] :consumer_group Kafka consumer group name (required)
  # @option opts [String] :consumer_id (random) Kafka consumer id
  # @option opts [Fixnum] :timeout (5) timeout in seconds to wait for a message
  def initialize(opts = {})
    opts = parse_opts(opts)

    @consumer = "#{opts[:consumer_group]}:#{opts[:consumer_id]}"
    @redis = Redis.new(host: opts[:host], port: opts[:port], id: @consumer)
    @topic = "topics:#{opts[:topic]}"
    @timeout = opts[:timeout] > 0 ? opts[:timeout] : 5
  end

  # Consumes the last message.
  #
  # @return [nil, String]
  #
  # @example
  #   pop { |msg| puts "I received #{msg}" }
  def pop
    res = @redis.blpop(@topic, timeout: @timeout)

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
  ensure
    if res && !raised
      @redis.rpush("acks", "#{topic}:#{partition}:#{offset}") if res
    end
  end

  private

  def parse_opts(opts)
    options = DEFAULTS.dup.merge(opts)
    options[:port] = Integer(options[:port])
    options[:timeout] = Integer(options[:timeout])
    options[:consumer_id] = SecureRandom.hex if !options[:consumer_id]

    REQUIRED.each do |opt|
      raise "#{opt} not provided" if !options[opt]
    end

    options
  end
end

rufka = Rufka.new(topic: "test-rafka", consumer_group: "foo", consumer_id: "asemas")
require 'pry-byebug'; binding.pry

rufka.pop

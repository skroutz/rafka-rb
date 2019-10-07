require "redis"

require "rafka/errors"
require "rafka/generic_commands"
require "rafka/message"
require "rafka/version"

require "rafka/consumer"
require "rafka/producer"

module Rafka
  REDIS_DEFAULTS = {
    host: "localhost",
    port: 6380
  }.freeze

  # Server errors upon which we should retry the operation.
  RETRIABLE_ERRORS = [
    "CONS Server shutdown"
  ].freeze

  # Wraps errors from redis-rb to our own error classes
  def self.wrap_errors
    yield
  rescue Redis::CommandError => e
    raise ProduceError, e.message[5..-1] if e.message.start_with?("PROD ")
    raise ConsumeError, e.message[5..-1] if e.message.start_with?("CONS ")
    raise CommandError, e.message
  end

  # Retries the operation upon Redis::CommandError
  def self.with_retry(max_retries=15)
    retries = 0

    begin
      yield
    rescue Redis::CommandError => e
      if RETRIABLE_ERRORS.include?(e.message) && retries < max_retries
        sleep 1
        retries += 1
        retry
      end

      raise e
    end
  end
end

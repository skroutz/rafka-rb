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
    port: 6380,
    reconnect_attempts: 5
  }.freeze

  def self.wrap_errors
    yield
  rescue Redis::CommandError => e
    raise ProduceError, e.message[5..-1] if e.message.start_with?("PROD ")
    raise ConsumeError, e.message[5..-1] if e.message.start_with?("CONS ")
    raise CommandError, e.message
  end
end

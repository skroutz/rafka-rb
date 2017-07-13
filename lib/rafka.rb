require "redis"

require "rafka/errors"
require "rafka/generic_commands"
require "rafka/message"
require "rafka/version"

require "rafka/consumer"
require "rafka/producer"

module Rafka
  DEFAULTS = {
    host: "localhost",
    port: 6380,
    reconnect_attempts: 5,
  }

  def self.wrap_errors
    yield
  rescue Redis::CommandError => e
    case
    when e.message.start_with?("PROD ")
      raise ProduceError, e.message[5..-1]
    when e.message.start_with?("CONS ")
      raise ConsumeError, e.message[5..-1]
    else
      raise CommandError, e.message
    end
  end
end


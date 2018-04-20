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

  # redis-rb until 3.2.1 didn't retry to connect on
  # Redis::CannotConnectError (eg. when rafka is down) so we manually retry
  # 5 times
  #
  # TODO(agis): get rid of this method when we go to 3.2.1 or later, because
  # https://github.com/redis/redis-rb/pull/476/
  def self.with_retry(times: REDIS_DEFAULTS[:reconnect_attempts], every_sec: 1)
    attempts = 0

    begin
      yield
    rescue Redis::CannotConnectError => e
      if Gem::Version.new(Redis::VERSION) < Gem::Version.new("3.2.2")
        if attempts < times
          attempts += 1
          sleep every_sec
          retry
        end
      end

      raise e
    end
  end
end


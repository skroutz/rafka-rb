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
    reconnect_attempts: 0,
  }
end


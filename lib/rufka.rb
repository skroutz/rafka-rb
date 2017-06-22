require "redis"

require "rufka/errors"
require "rufka/generic_commands"
require "rufka/message"
require "rufka/version"

require "rufka/consumer"
require "rufka/producer"

module Rufka
  DEFAULTS = {
    host: "localhost",
    port: 6380,
    reconnect_attempts: 0,
  }
end


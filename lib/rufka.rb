require "redis"
require "rufka/consumer"
require "rufka/errors"
require "rufka/message"
require "rufka/producer"
require "rufka/version"

module Rufka
  DEFAULTS = {
    host: "localhost",
    port: 6380,
    reconnect_attempts: 0,
  }
end


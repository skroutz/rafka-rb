require "redis"
require "rufka/consumer"
require "rufka/producer"
require "rufka/version"

module Rufka
  DEFAULTS = {
    host: "localhost",
    port: 6380,
    reconnect_attempts: 0,
  }
end


module Rufka
  # Commands available on both {Producer} and {Consumer}.
  module GenericCommands
    # @see https://redis.io/commands/ping
    def ping
      @redis.ping
    end

    # @see https://redis.io/commands/quit
    def quit
      @redis.quit
    end
  end
end

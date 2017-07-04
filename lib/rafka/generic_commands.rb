module Rafka
  # Commands available on both {Producer} and {Consumer}.
  module GenericCommands
    # @see https://redis.io/commands/ping
    def ping
      @redis.ping
    end

    # Closes the connection.
    #
    # @see https://redis.io/commands/quit
    def close
      @redis.quit
    end
  end
end

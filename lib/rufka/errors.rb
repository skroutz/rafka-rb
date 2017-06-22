module Rufka
  class Error < StandardError
  end

  class MalformedMessage < Error
    def initialize(msg)
      @msg = msg
    end

    def to_s
      "The message #{@msg.inspect} could not be parsed"
    end
  end
end

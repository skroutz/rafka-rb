module Rafka
  class Error < StandardError
  end

  class MalformedMessageError < Error
    def initialize(msg)
      @msg = msg
    end

    def to_s
      "The message #{@msg.inspect} could not be parsed"
    end
  end

  # Generic command error
  class CommandError < Error
  end

  class ProduceError < CommandError
  end

  class ConsumeError < CommandError
  end
end

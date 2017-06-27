module Rafka
  # Message represents a message consumed from a topic.
  class Message
    attr :topic, :partition, :offset, :value

    def initialize(msg)
      if !msg.is_a?(Array) || msg.size != 8
        raise MalformedMessageError.new(msg)
      end

      @topic     = msg[1]
      @partition = msg[3]
      @offset    = msg[5]
      @value     = msg[7]
    end
  end
end

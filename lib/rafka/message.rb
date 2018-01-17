module Rafka
  # Message represents a message consumed from a topic.
  class Message
    attr :topic, :partition, :offset, :value

    def initialize(msg)
      if !msg.is_a?(Array) || msg.size != 8
        raise MalformedMessageError.new(msg)
      end

      @topic = msg[1]

      begin
        @partition = Integer(msg[3])
        @offset = Integer(msg[5])
      rescue ArgumentError
        raise MalformedMessageError.new(msg)
      end

      @value = msg[7]
    end
  end
end

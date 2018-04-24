require "minitest/autorun"
require "rafka"

class ConsumerTest < Minitest::Test
  def test_prepare_for_commit
    consumer = Rafka::Consumer.new(group: "foo", topic: "bar")

    msgs = [
      ["topic", "foo", "partition", 0, "offset", 1, "value", "a"],
      ["topic", "foo", "partition", 0, "offset", 0, "value", "a"],
      ["topic", "foo", "partition", 0, "offset", 13, "value", "a"],
      ["topic", "foo", "partition", 0, "offset", 12, "value", "a"],
      ["topic", "foo", "partition", 1, "offset", 4, "value", "a"],
      ["topic", "foo", "partition", 1, "offset", 3, "value", "a"],
      ["topic", "foo", "partition", 2, "offset", 50, "value", "a"],
      ["topic", "foo", "partition", 2, "offset", 60, "value", "a"],
      ["topic", "foo", "partition", 2, "offset", 60, "value", "a"],
      ["topic", "foo", "partition", 2, "offset", 70, "value", "a"],
      ["topic", "bar", "partition", 4, "offset", 3, "value", "a"],
      ["topic", "bar", "partition", 4, "offset", 123, "value", "a"],
      ["topic", "bar", "partition", 4, "offset", 999, "value", "a"],
      ["topic", "bar", "partition", 3, "offset", 70, "value", "a"],
      ["topic", "baz", "partition", 0, "offset", 999, "value", "a"]
    ].map { |x| Rafka::Message.new(x) }

    expected = {
      "foo" => { 0 => 13, 1 => 4, 2 => 70 },
      "bar" => { 4 => 999, 3 => 70 },
      "baz" => { 0 => 999 }
    }

    actual = consumer.send(:prepare_for_commit, *msgs)
    assert_equal(actual, expected)

    msg = Rafka::Message.new(["topic", "foo", "partition", 1, "offset", 1, "value", "a"])
    actual = consumer.send(:prepare_for_commit, msg)
    assert_equal(actual, "foo" => { 1 => 1 })

    msg = Rafka::Message.new(["topic", "foo", "partition", 0, "offset", 0, "value", "a"])
    actual = consumer.send(:prepare_for_commit, msg)
    assert_equal(actual, "foo" => { 0 => 0 })

    assert_equal(consumer.send(:prepare_for_commit), {})
  end
end

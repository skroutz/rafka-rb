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

  def test_consume_block_no_message
    cons = Rafka::Consumer.new(group: "foo", topic: "bar")

    def cons.consume_one(_)
      nil
    end

    cons.consume do |msg|
      assert_kind_of Rafka::Message, msg
    end
  end

  def test_blpop_arg
    cons = Rafka::Consumer.new(
      group: "foo", topic: "bar", librdkafka: { test1: 2, test2: "a", "foo.bar" => true }
    )
    assert_equal cons.blpop_arg, 'topics:bar:{"test1":2,"test2":"a","foo.bar":true}'

    cons = Rafka::Consumer.new(group: "foo", topic: "bar", librdkafka: {})
    assert_equal cons.blpop_arg, "topics:bar"

    cons = Rafka::Consumer.new(group: "foo", topic: "bar", librdkafka: nil)
    assert_equal cons.blpop_arg, "topics:bar"

    cons = Rafka::Consumer.new(group: "foo", topic: "bar")
    assert_equal cons.blpop_arg, "topics:bar"
  end

  def test_multiple_topics
    cons = Rafka::Consumer.new(group: "foo", topic: %w[foo bar])
    assert_equal cons.blpop_arg, "topics:foo,bar"
  end
end

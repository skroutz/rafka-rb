rafka-rb
===============================================================================
[![Build Status](https://api.travis-ci.org/skroutz/rafka-rb.svg?branch=master)](https://travis-ci.org/skroutz/rafka-rb)
[![Gem Version](https://badge.fury.io/rb/rafka.svg)](https://badge.fury.io/rb/rafka)
[![Documentation](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/skroutz/rafka-rb)

rafka-rb is a Ruby client library for [Rafka](https://github.com/skroutz/rafka), providing Consumer and Producer implementations with simple semantics.

Refer to the [API documentation](http://www.rubydoc.info/github/skroutz/rafka-rb)
for more information.






Features
-------------------------------------------------------------------------------

- Consumer
  - consumer groups
  - support for consuming in batches
  - offsets may be managed automatically or manually
- Producer
  - support for partition hashing key








Getting started
-------------------------------------------------------------------------------
Install rafka-rb:

```shell
$ gem install rafka
```

If you're using Bundler, add it to your Gemfile:
```ruby
gem "rafka"
```
and run `bundle install`.






Usage
-------------------------------------------------------------------------------

### Producer

```ruby
producer = Rafka::Producer.new(host: "localhost", port: 6380)
producer.produce("greetings", "Hello there!")
```

Refer to the [Producer API documentation](http://www.rubydoc.info/github/skroutz/rafka-rb/Rafka/Producer)
for more information.











### Consumer

```ruby
consumer = Rafka::Consumer.new(topic: "greetings", group: "myapp")
msg = consumer.consume
msg.value # => "Hello there!"

# with a block
consumer.consume { |msg| puts "Received: #{msg.value}" } # => "Hello there!"
```

Offsets are managed automatically by default. If you need more control you can
turn off the feature and manually commit offsets:

```ruby
consumer = Rafka::Consumer.new(topic: "greetings", group: "myapp", auto_commit: false)

# commit a single offset
msg = consumer.consume
consumer.commit(msg) # => true

# or commit a bunch of offsets
msg1 = consumer.consume
msg2 = consumer.consume
consumer.commit(msg1, msg2) # => true
```

Consumers may also set their own custom [librdkafka configuration](https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md):

```ruby
consumer = Rafka::Consumer.new(
  topic: "greetings", group: "myapp", librdkafka: { "auto.offset.reset" => "earliest" }
)
```

Consumers can subscribe to multiple topics:

```ruby
consumer = Rafka::Consumer.new(topic: "topic_1")
consumer = Rafka::Consumer.new(topic: ["topic_1", "topic_2"])
consumer = Rafka::Consumer.new(topic: "topic_1,topic_2")
```

Refer to the [Consumer API documentation](http://www.rubydoc.info/github/skroutz/rafka-rb/Rafka/Consumer)
for more information.











Development
-------------------------------------------------------------------------------

Running Rubocop:

```shell
$ bundle exec rake rubocop
```

Unit tests run as follows:

```shell
$ bundle exec rake test
```


rafka-rb is indirectly tested by [Rafka's end-to-end tests](https://github.com/skroutz/rafka/tree/master/test).






License
-------------------------------------------------------------------------------
rafka-rb is released under the GNU General Public License version 3. See [COPYING](COPYING).

rafka-rb: Ruby driver for Rafka
===============================================================================
[![Gem Version](https://badge.fury.io/rb/rafka.svg)](https://badge.fury.io/rb/rafka-rb)
[![Documentation](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/skroutz/rafka-rb)

rafka-rb is a thin Ruby client library for [Rafka](https://github.com/skroutz/rafka),
providing a consumer and a producer with simple semantics. It is backed by
[redis-rb](https://github.com/redis/redis-rb).

View the [API documentation](http://www.rubydoc.info/github/skroutz/rafka-rb).

Status
-------------------------------------------------------------------------------

Rafka is not yet stable and therefore is _not_ recommended for production use.









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
require "rafka"

prod = Rafka::Producer.new(host: "localhost", port: 6380)

# Produce to topic "greetings". The message will be assigned to a random partition.
prod.produce("greetings", "Hello there!")

# Produce using a key. Two or more messages with the same key will always be assigned to the same partition.
prod.produce("greetings", "Hello there!", key: "hi")
prod.produce("greetings", "Hi there!", key: "hi")
```




### Consumer

```ruby
require "rafka"

cons = Rafka::Consumer.new(topic: "greetings", group: "myapp", id: "greeter1")
cons.consume # => "Hello there!"

# with a block
cons.consume { |msg| puts "Received: #{msg.value}" } # => "Hello there!"
```

`Rafka::Consumer#consume` automatically commits the offsets when the given block
is executed without raising any exceptions.

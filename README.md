rafka-rb: Ruby driver for Rafka
===============================================================================
[![Gem Version](https://badge.fury.io/rb/rafka.svg)](https://badge.fury.io/rb/rafka-rb)
[![Documentation](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/skroutz/rafka-rb)

Rafka is a thin Ruby client library for [Rafka](https://github.com/skroutz/rafka-rb),
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
prod.produce("greetings", "Hello there!") # produce to topic "greetings"
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

Rufka: Ruby driver for Rafka
===============================================================================
[![Gem Version](https://badge.fury.io/rb/rufka.svg)](https://badge.fury.io/rb/rufka)
[![Documentation](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/skroutz/rufka)

Rufka is a thin Ruby client for [Rafka](https://github.com/skroutz/rafka),
providing a consumer and a producer with simple semantics. It is backed by
[redis-rb](https://github.com/redis/redis-rb).

View the [API documentation](http://www.rubydoc.info/github/skroutz/rufka).

Status
-------------------------------------------------------------------------------

Rufka is not yet stable and therefore is _not_ recommended for production use.





Usage
-------------------------------------------------------------------------------

### Producer

```ruby
prod = Rufka::Producer.new(host: "localhost", port: 6380)
prod.produce("greetings", "Hello there!") # produce to topic "greetings"
```




### Consumer

```ruby
cons = Rufka::Consumer.new(topic: "greetings", group: "myapp", id: "greeter1")
cons.consume # => "Hello there!"

# with a block
cons.consume { |msg| puts "Received: #{msg.value}" } # => "Hello there!"
```

`Rafka::Consumer#consume` automatically commits the offsets when the given block
is executed without raising any exceptions.

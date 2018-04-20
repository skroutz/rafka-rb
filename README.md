rafka-rb: Ruby driver for Rafka
===============================================================================
[![Gem Version](https://badge.fury.io/rb/rafka.svg)](https://badge.fury.io/rb/rafka-rb)
[![Documentation](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/skroutz/rafka-rb)

rafka-rb is a Ruby client for [Rafka](https://github.com/skroutz/rafka),
providing consumer and producer implementations with simple semantics.
It is backed by [redis-rb](https://github.com/redis/redis-rb).

Refer to the [API documentation](http://www.rubydoc.info/github/skroutz/rafka-rb)
for more information.



Features
-------------------------------------------------------------------------------

- Consumer implementation
  - consumer groups
  - offsets are managed automatically
- Producer implementation
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

See the [API documentation of `Producer`](http://www.rubydoc.info/github/skroutz/rafka-rb/Rafka/Producer) for more information.



### Consumer

```ruby
consumer = Rafka::Consumer.new(topic: "greetings", group: "myapp")
consumer.consume.value # => "Hello there!"

# with a block
consumer.consume { |msg| puts "Received: #{msg.value}" } # => "Hello there!"
```

See the [API documentation of `Consumer`](http://www.rubydoc.info/github/skroutz/rafka-rb/Rafka/Consumer) for more information.







Testing
-------------------------------------------------------------------------------

Unit tests run as follows:

```shell
$ bundle exec rake test
```


rafka-rb is indirectly tested by [Rafka's end-to-end tests](https://github.com/skroutz/rafka/tree/master/test).






License
-------------------------------------------------------------------------------
rafka-rb is released under the GNU General Public License version 3. See [COPYING](COPYING).

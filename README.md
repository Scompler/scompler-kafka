## 🚨 NOTE: The repository has been migrated to Gitlab. Please do not use it anymore. Link: https://gitlab.scompler.dev/scompler-org/scompler-kafka

# Scompler::Kafka

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scompler-kafka', git: 'https://github.com/Scompler/scompler-kafka.git', tag: 'v0.1.3'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scompler-kafka

## Usage

The simple usage example.

First of all you need to define a producer class

```ruby
class GreetingsProducer < Scompler::Kafka::BaseProducer
  topic :greetings,
        num_partitions: 4,
        replication_factor: 2,
        config: { 'max.message.bytes' => 100_000 }

  def produce(message = 'Hello World')
    produce_to(:greetings, {message: message})
  end
end
```

See the full list of topic config parameters at https://kafka.apache.org/documentation/#topicconfigs

Now you need to create a Kafka topic on backend side

```ruby
Scompler::Kafka::SyncTopics.call(GreetingsProducer)
```

And finally you can send a producer message to the specific topic

```ruby
GreetingsProducer.produce
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/scompler-kafka.

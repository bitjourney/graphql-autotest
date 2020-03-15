# GraphQL::Autotest

GraphQL::Autotest tests your GraphQL API with auto-generated queries.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql-autotest'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install graphql-autotest

## Usage

```ruby
class YourSchema < GraphQL::Schema
end

runner = GraphQL::Autotest::Runner.new(
  schema: YourSchema,
  # The context that is passed to GraphQL::Schema.execute
  context: { current_user: User.first },
)

# * Generate queries from YourSchema
# * Then execute the queries
# * Raise an error if the results contain error(s)
runner.report!
```

### Configuration

TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bitjourney/graphql-autotest.


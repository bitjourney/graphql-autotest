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

### Generate queries and execute them

```ruby
require 'graphql/autotest'

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

### Generate queries from `GraphQL::Schema` (not execute)

```ruby
require 'graphql/autotest'

class YourSchema < GraphQL::Schema
end

fields = GraphQL::Autotest::QueryGenerator.generate(document: YourSchema.to_document)

# Print all generated queries
fields.each do |field|
  puts field.to_query
end
```

### Generate queries from file (not execute)

It is useful for non graphql-ruby user.

```ruby
require 'graphql/autotest'

fields = GraphQL::Autotest::QueryGenerator.from_file(path: 'path/to/definition.graphql')

# Print all generated queries
fields.each do |field|
  puts field.to_query
end
```

### Configuration

`GraphQL::Autotest::Runner.new`, `GraphQL::Autotest::QueryGenerator.generate` and `GraphQL::Autotest::QueryGenerator.from_file` receives the following arguments to configure how to generates queries.

* `arguments_fetcher`
  * A proc to fill arguments of the received field.
  * default: `GraphQL::Autotest::ArgumentsFetcher::DEFAULT`, that allows empty arguments, and arguments that has no required argument.
  * You need to specify the proc if you need to test field that has required arguments.
* `max_depth`
  * Max query depth.
  * default: 10
* `skip_if`
  * A proc to specify field that you'd like to skip to generate query.
  * default: skip nothing

For example:

```ruby
require 'graphql/autotest'

class YourSchema < GraphQL::Schema
end

# Fill `first` argument to reduce result size.
fill_first = proc do |field|
  field.arguments.any? { |arg| arg.name == 'first' } && { first: 5 }
end

# Skip a sensitive field
skip_if = proc do |field|
  field.name == 'sensitiveField'
end

fields = GraphQL::Autotest::QueryGenerator.generate(
  document: YourSchema.to_document,
  arguments_fetcher: GraphQL::Autotest::ArgumentsFetcher.combine(
    fill_first,
    GraphQL::Autotest::ArgumentsFetcher::DEFAULT,
  ),
  max_depth: 5,
  skip_if: skip_if,
)

# Print all generated queries
fields.each do |field|
  puts field.to_query
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bitjourney/graphql-autotest.


require "bundler/gem_tasks"
require 'rake/testtask'
task :default => [:test, :smoke]

Rake::TestTask.new do |test|
  test.libs << 'test'
  test.test_files = Dir['test/**/*_test.rb']
  test.verbose = true
end

task :smoke do
  require 'graphql/autotest'
  definition = `curl https://raw.githubusercontent.com/kibela/kibela-api-v1-document/master/schema.graphql`
  fields = GraphQL::Autotest::QueryGenerator.from_file(content: definition, max_depth: 6)
  fields.each do |f|
    GraphQL.parse(f.to_query)
  end

  puts "#{fields.size} fields are successfully generated🎉"
end

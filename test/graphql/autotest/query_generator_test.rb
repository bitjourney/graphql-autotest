require 'test_helper'

class QueryGeneratorTest < Minitest::Test
  class EmptySchema < GraphQL::Schema
    class QueryType < GraphQL::Schema::Object
      description 'an empty query'
    end

    query QueryType
  end

  def test_empty_schema
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: EmptySchema)
    assert fields.is_a? Array
    assert_equal 1, fields.size
    assert_equal '__typename', fields.first.to_query
  end
end

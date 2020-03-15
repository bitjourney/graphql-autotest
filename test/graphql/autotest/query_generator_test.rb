require 'test_helper'

class QueryGeneratorTest < Minitest::Test
  class EmptySchema < GraphQL::Schema
    class QueryType < GraphQL::Schema::Object
    end

    query QueryType
  end

  def test_empty_schema
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: EmptySchema)
    assert_query ['__typename'], fields
  end

  class SimpleSchema < GraphQL::Schema
    class NoteType < GraphQL::Schema::Object
      field :title, String, null: false
      field :content, String, null: false
    end

    class QueryType < GraphQL::Schema::Object
      field :latest_note, NoteType, null: true
    end

    query QueryType
  end

  def test_simple_schema
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: SimpleSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        title
        content
        __typename
      }
    GRAPHQL
  end

  def test_simple_schema_with_skip_if
    skip_if = -> (field, **) { field.name == 'content' }
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: SimpleSchema, skip_if: skip_if)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        title
        __typename
      }
    GRAPHQL
  end

  class NestSchema < GraphQL::Schema
    class AvatarType < GraphQL::Schema::Object
      field :data, String, null: false
    end

    class UserType < GraphQL::Schema::Object
      field :name, String, null: false
      field :avatar, AvatarType, null: true
    end

    class NoteType < GraphQL::Schema::Object
      field :title, String, null: false
      field :content, String, null: false
      field :author, UserType, null: false
    end

    class QueryType < GraphQL::Schema::Object
      field :latest_note, NoteType, null: true
    end

    query QueryType
  end

  def test_nest_schema
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: NestSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        title
        content
        author {
          name
          avatar {
            data
            __typename
          }

          __typename
        }

        __typename
      }
    GRAPHQL
  end

  def test_nest_schema_with_max_depth_1
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: NestSchema, max_depth: 1)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        title
        content
        author {
          __typename
        }

        __typename
      }
    GRAPHQL
  end

  def test_nest_schema_with_max_depth_2
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: NestSchema, max_depth: 2)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        title
        content
        author {
          name
          avatar {
            __typename
          }

          __typename
        }

        __typename
      }
    GRAPHQL
  end

  class CircularSchema < GraphQL::Schema
    class UserType < GraphQL::Schema::Object
      field :name, String, null: false
      field :partner, UserType, null: true
    end

    class QueryType < GraphQL::Schema::Object
      field :user, UserType, null: true
    end

    query QueryType
  end

  def test_circular_schema
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: CircularSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      user {
        name
        partner {
          name
          partner {
            __typename
          }

          __typename
        }

        __typename
      }
    GRAPHQL
  end

  class CircularSchema2 < GraphQL::Schema
    class NoteType < GraphQL::Schema::Object
    end

    class UserType < GraphQL::Schema::Object
      field :name, String, null: false
      field :latest_note, NoteType, null: true
    end

    # Re-open NoteType class after UserType definition to refer UserType class
    class NoteType < GraphQL::Schema::Object
      field :title, String, null: false
      field :author, UserType, null: false
    end

    class QueryType < GraphQL::Schema::Object
      field :user, UserType, null: true
    end

    query QueryType
  end

  def test_circular_schema2
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: CircularSchema2)
    assert_query [<<~GRAPHQL, '__typename'], fields
      user {
        name
        latestNote {
          title
          author {
            name
            latestNote {
              __typename
            }

            __typename
          }

          __typename
        }

        __typename
      }
    GRAPHQL
  end

  class ArgumentsSchema < GraphQL::Schema
    class UserType < GraphQL::Schema::Object
      field :name, String, null: false
    end

    class QueryType < GraphQL::Schema::Object
      field :users_with_optional_first, [UserType], null: true do
        argument :first, Integer, required: false
      end

      field :users_with_required_first, [UserType], null: true do
        argument :first, Integer, required: true
      end
    end

    query QueryType
  end

  def test_arguments_schema1
    fields = GraphQL::Autotest::QueryGenerator.generate(schema: ArgumentsSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      usersWithOptionalFirst {
        name
        __typename
      }
    GRAPHQL
  end

  def test_arguments_schema2
    fetcher = GraphQL::Autotest::ArgumentsFetcher.combine(
      GraphQL::Autotest::ArgumentsFetcher::DEFAULT,
      -> (field, **) { field.arguments.keys == ['first'] && { first: 4} }
    )
    fields = GraphQL::Autotest::QueryGenerator.generate(
      schema: ArgumentsSchema,
      arguments_fetcher: fetcher,
    )
    assert_query [<<~GRAPHQL, <<~GRAPHQL2, '__typename'], fields
      usersWithOptionalFirst {
        name
        __typename
      }
    GRAPHQL
      usersWithRequiredFirst(first: 4) {
        name
        __typename
      }
    GRAPHQL2
  end

  private def assert_query(expected, got)
    assert got.is_a? Array
    assert_equal expected, got.map(&:to_query)
  end
end
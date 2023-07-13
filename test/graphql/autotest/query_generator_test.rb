require 'test_helper'

class QueryGeneratorTest < Minitest::Test
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
    fields = generate(schema: SimpleSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        content
        title
        __typename
      }
    GRAPHQL
  end

  def test_simple_schema_with_skip_if
    skip_if = -> (field, **) { field.name == 'content' }
    fields = generate(schema: SimpleSchema, skip_if: skip_if)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        title
        __typename
      }
    GRAPHQL
  end

  class ScalarTypeSchema < GraphQL::Schema
    class DateTime < GraphQL::Schema::Scalar
    end

    class NoteType < GraphQL::Schema::Object
      field :title, String, null: false
      field :updated_at, DateTime, null: false
    end

    class QueryType < GraphQL::Schema::Object
      field :latest_note, NoteType, null: true
    end

    query QueryType
  end

  def test_scalar_type_schema
    fields = generate(schema: ScalarTypeSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        title
        updatedAt
        __typename
      }
    GRAPHQL
  end

  class UnionTypeSchema < GraphQL::Schema
    class NoteType < GraphQL::Schema::Object
      field :title, String, null: false
      field :content, String, null: false
    end

    class CommentType < GraphQL::Schema::Object
      field :content, String, null: false
    end

    class LikableType < GraphQL::Schema::Union
      possible_types NoteType, CommentType
    end

    class LikeType < GraphQL::Schema::Object
      field :target, LikableType, null: false
      field :by, String, null: false
    end

    class QueryType < GraphQL::Schema::Object
      field :latest_like, LikeType, null: true
    end

    query QueryType
  end

  def test_union_type_schema
    fields = generate(schema: UnionTypeSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestLike {
        by
        target {
          ... on Comment {
            content
            __typename
          }

          ... on Note {
            content
            title
            __typename
          }

          __typename
        }

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
    fields = generate(schema: NestSchema)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        content
        title
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
    fields = generate(schema: NestSchema, max_depth: 1)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        content
        title
        author {
          __typename
        }

        __typename
      }
    GRAPHQL
  end

  def test_nest_schema_with_max_depth_2
    fields = generate(schema: NestSchema, max_depth: 2)
    assert_query [<<~GRAPHQL, '__typename'], fields
      latestNote {
        content
        title
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
    fields = generate(schema: CircularSchema)
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
    fields = generate(schema: CircularSchema2)
    assert_query [<<~GRAPHQL, '__typename'], fields
      user {
        name
        latestNote {
          title
          author {
            name
            latestNote {
              title
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
    fields = generate(schema: ArgumentsSchema)
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
      -> (field, **) { field.arguments.map(&:name) == ['first'] && { first: 4} }
    )
    fields = generate(
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

  class SubFieldArgumentSchema < GraphQL::Schema
    class ItemType < GraphQL::Schema::Object
      field :title, String, null: false do
        argument :lang, String
      end
    end

    class QueryType < GraphQL::Schema::Object
      field :item, ItemType, null: true
    end

    query QueryType
  end

  def test_sub_field_argument_schema
    fetcher = GraphQL::Autotest::ArgumentsFetcher.combine(
      GraphQL::Autotest::ArgumentsFetcher::DEFAULT,
      -> (field, **) { field.arguments.any? { |arg| arg.name == 'lang' } && { lang: %("ja")} }
    )
    fields = generate(
      schema: SubFieldArgumentSchema,
      arguments_fetcher: fetcher,
    )
    assert_query [<<~GRAPHQL, '__typename'], fields
      item {
        title(lang: "ja")
        __typename
      }
    GRAPHQL
  end

  private def generate(schema:, **kw)
    GraphQL::Autotest::QueryGenerator.generate(document: schema.to_document, **kw)
  end

  private def assert_query(expected, got)
    assert got.is_a? Array
    assert_equal expected, got.map { |f| f.to_query(root: false) }
  end
end

module GraphQL
  module Autotest
    class QueryGenerator
      attr_reader :schema, :arguments_fetcher, :max_depth, :skip_if
      private :schema, :arguments_fetcher, :max_depth, :skip_if

      # See Runner#initialize for arguments documentation.
      def self.generate(schema:, arguments_fetcher: ArgumentsFetcher::DEFAULT, max_depth: Float::INFINITY, skip_if: -> (_field, **) { false })
        self.new(schema: schema, arguments_fetcher: arguments_fetcher, max_depth: max_depth, skip_if: skip_if).generate
      end

      def initialize(schema:, arguments_fetcher:, max_depth: , skip_if:)
        @schema = schema
        @arguments_fetcher = arguments_fetcher
        @max_depth = max_depth
        @skip_if = skip_if
      end

      def generate
        query_type = type_definition('Query')
        testable_fields(query_type)
      end

      # It returns testable fields as a tree.
      # "Testable" means that it can fill the arguments.
      private def testable_fields(type_def, called_fields: Set.new, depth: 0, ancestors: [])
        return [Field::TYPE_NAME] if depth > max_depth

        type_def.fields.map do |name, f|
          next if skip_if.call(f, ancestors: ancestors)

          arguments = arguments_fetcher.call(f, ancestors: ancestors)
          next unless arguments
          already_called_key = [type_def, name]
          next if called_fields.include?(already_called_key) && name != 'id'

          called_fields << already_called_key

          field_type = unwrap f.type
          field_type = field_type.to_graphql if field_type.respond_to?(:to_graphql)

          case field_type
          when nil, GraphQL::ScalarType, GraphQL::EnumType
            Field.new(name: f.name, children: nil, arguments: arguments)
          when GraphQL::UnionType
            possible_types = field_type.possible_types.map do |t|
              children = testable_fields(t, called_fields: called_fields.dup, depth: depth + 1, ancestors: [f, *ancestors])
              Field.new(name: "... on #{t}", children: children)
            end
            Field.new(name: f.name, children: possible_types + [Field::TYPE_NAME], arguments: arguments)
          else
            children = testable_fields(field_type, called_fields: called_fields.dup, depth: depth + 1, ancestors: [f, *ancestors])

            Field.new(
              name: f.name,
              children: children,
              arguments: arguments,
            )
          end
        end.compact + [Field::TYPE_NAME]
      end

      private def type_definition(name)
        schema.types[name]
      end

      private def unwrap(type)
        return type unless type.respond_to?(:of_type)

        unwrap(type.of_type)
      end
    end
  end
end

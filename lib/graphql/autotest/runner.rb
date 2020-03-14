module GraphQL
  module Autotest
    class Runner
      attr_reader :schema, :context, :fetch_arguments, :max_depth, :skip_if
      private :schema, :context, :fetch_arguments, :max_depth, :skip_if

      # @param schema [Class<GraphQL::Schema>]
      # @param context [Hash] it passes to GraphQL::Schema.execute
      # @param fetch_arguments [Proc] A proc receives a field and ancestors keyword argument, and it returns a Hash. The hash is passed to call the field.
      # @param max_depth [Integer] Max query depth. It is recommended to specify to avoid too large query.
      # @param skip_if [Proc] A proc receives a field and ancestors keyword argument, and it returns a boolean. If it returns ture, the field is skipped.
      def initialize(schema:, context:, fetch_arguments:, max_depth: Float::INFINITY, skip_if: -> (_field) { false })
        @schema = schema
        @context = context
        @fetch_arguments = fetch_arguments
        @max_depth = max_depth
        @skip_if = skip_if
      end

      def report(dry_run: false)
        report = Report.new(executions: [])

        query_type = type_definition('Query')
        fields = testable_fields(query_type)
        fields.each do |f|
          q = f.to_query
          q = <<~GRAPHQL
            {
            #{q.indent(2)}
            }
          GRAPHQL

          result = if dry_run
                     {}
                   else
                     schema.execute(
                       document: GraphQL.parse(q),
                       variables: {},
                       operation_name: nil,
                       context: context,
                     )
                   end
          report.executions << Report::Execution.new(query: q, result: result)
        end

        report
      end

      # It returns testable fields as a tree.
      # "Testable" means that it can fill the arguments.
      private def testable_fields(type_def, called_fields: Set.new, depth: 0, ancestors: [])
        return [Field::TYPE_NAME] if depth > max_depth

        type_def.fields.map do |name, f|
          next if skip_if.call(f, ancestors: ancestors)

          arguments = fetch_arguments.call(f, ancestors: ancestors)
          next unless arguments
          already_called_key = [type_def, name]
          next if called_fields.include?(already_called_key) && name != 'id'

          called_fields << already_called_key

          field_type = unwrap f.type
          field_type_def = type_definition(field_type.name)

          case field_type_def
          when nil, GraphQL::ScalarType, GraphQL::EnumType
            Field.new(name: f.name, children: nil, arguments: arguments)
          when GraphQL::UnionType
            possible_types = field_type_def.possible_types.map do |t|
              children = testable_fields(t, called_fields: called_fields.dup, depth: depth + 1, ancestors: [f, *ancestors])
              Field.new(name: "... on #{t}", children: children)
            end
            Field.new(name: f.name, children: possible_types + [Field::TYPE_NAME], arguments: arguments)
          else
            children = testable_fields(field_type_def, called_fields: called_fields.dup, depth: depth + 1, ancestors: [f, *ancestors])

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

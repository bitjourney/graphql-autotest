module GraphQL
  module Autotest
    class QueryGenerator
      attr_reader :document, :arguments_fetcher, :max_depth, :skip_if
      private :document, :arguments_fetcher, :max_depth, :skip_if

      def self.from_file(path: nil, content: nil, **kw)
        raise ArgumentError, "path or content is required" if !path && !content

        content ||= File.read(path)
        document = GraphQL.parse(content)
        generate(document: document, **kw)
      end

      # See Runner#initialize for arguments documentation.
      def self.generate(document:, arguments_fetcher: ArgumentsFetcher::DEFAULT, max_depth: 0, skip_if: -> (_field, **) { false })
        self.new(document: document, arguments_fetcher: arguments_fetcher, max_depth: max_depth, skip_if: skip_if).generate
      end

      def initialize(document:, arguments_fetcher:, max_depth: , skip_if:)
        @document = document
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

        type_def.fields.map do |f|
          next if skip_if.call(f, ancestors: ancestors)

          arguments = arguments_fetcher.call(f, ancestors: ancestors)
          next unless arguments
          already_called_key = [type_def, f.name, ancestors.first&.name]
          next if called_fields.include?(already_called_key) && f.name != 'id'

          called_fields << already_called_key

          field_type = Util.unwrap f.type
          field_type_def = type_definition(field_type.name)

          case field_type_def
          when nil, GraphQL::Language::Nodes::EnumTypeDefinition, GraphQL::Language::Nodes::ScalarTypeDefinition
            Field.new(name: f.name, children: nil, arguments: arguments)
          when GraphQL::Language::Nodes::UnionTypeDefinition
            possible_types = field_type_def.types.map do |t|
              t_def = type_definition(t.name)
              children = testable_fields(t_def, called_fields: called_fields.dup, depth: depth + 1, ancestors: [f, *ancestors])
              Field.new(name: "... on #{t.name}", children: children)
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
        document.definitions.find { |f| f.name == name }
      end
    end
  end
end

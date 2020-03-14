module GraphQL
  module Autotest
    class Field < Struct.new(:name, :children, :arguments, keyword_init: true)
      TYPE_NAME = Field.new(name: '__typename', children: nil)

      def to_query
        return name unless children

        <<~GRAPHQL
          #{name}#{arguments_to_query} {
          #{children_to_query.indent(2)}
          }
        GRAPHQL
      end

      def children_to_query
        children.map do |child|
          child.to_query
        end.join("\n")
      end

      def arguments_to_query
        return unless arguments

        inner = arguments.map do |k, v|
          "#{k}: #{v}"
        end.join(', ')
        "(#{inner})"
      end
    end
  end
end

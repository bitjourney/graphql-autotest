module GraphQL
  module Autotest
    class Field < Struct.new(:name, :children, :arguments, keyword_init: true)
      TYPE_NAME = Field.new(name: '__typename', children: nil)

      def to_query
        return name unless children

        <<~GRAPHQL
          #{name}#{arguments_to_query} {
          #{indent(children_to_query, 2)}
          }
        GRAPHQL
      end

      private def children_to_query
        children.map do |child|
          child.to_query
        end.join("\n")
      end

      private def arguments_to_query
        return unless arguments
        return if arguments.empty?

        inner = arguments.map do |k, v|
          "#{k}: #{v}"
        end.join(', ')
        "(#{inner})"
      end

      private def indent(str, n)
        str.lines(chomp: true).map do |line|
          if line.empty?
            ""
          else
            " " * n + line
          end
        end.join("\n")
      end
    end
  end
end

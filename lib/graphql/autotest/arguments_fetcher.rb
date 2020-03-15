module GraphQL
  module Autotest
    module ArgumentsFetcher
      def self.combine(*strategy)
        -> (*args, **kwargs) do
          strategy.find do |s|
            r = s.call(*args, **kwargs)
            break r if r
          end
        end
      end

      # @param arg [GraphQL::Language::Nodes::InputValueDefinition]
      def self.non_null?(arg)
        arg.type.is_a?(GraphQL::Language::Nodes::NonNullType)
      end

      EMPTY = -> (field, ancestors:) { field.arguments.empty? && {} }
      NO_REQUIRED = -> (field, ancestors:) { field.arguments.none? { |arg| non_null?(arg) } && {} }
      DEFAULT = combine(EMPTY, NO_REQUIRED)
    end
  end
end

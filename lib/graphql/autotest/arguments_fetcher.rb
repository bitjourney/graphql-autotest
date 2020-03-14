module GraphQL
  module Autotest
    module ArgumentsFetcher
      EMPTY = -> (field, ancestors:) { field.arguments.empty? && {} }
      NO_REQUIRED = -> (field, ancestors:) { field.arguments.none? { |_k, v| v.type.non_null? } && {} }

      def self.combine(*strategy)
        -> (*args, **kwargs) do
          strategy.find do |s|
            r = s.call(*args, **kwargs)
            break r if r
          end
        end
      end
    end
  end
end

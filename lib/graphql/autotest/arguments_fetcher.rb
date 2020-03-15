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

      EMPTY = -> (field, ancestors:) { field.arguments.empty? && {} }
      NO_REQUIRED = -> (field, ancestors:) { field.arguments.none? { |arg| Util.non_null?(arg.type) } && {} }
      DEFAULT = combine(EMPTY, NO_REQUIRED)
    end
  end
end

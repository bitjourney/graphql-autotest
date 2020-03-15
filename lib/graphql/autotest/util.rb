module GraphQL
  module Autotest
    module Util
      extend self

      def non_null?(type)
        type.is_a?(GraphQL::Language::Nodes::NonNullType)
      end

      def unwrap(type)
        return type unless type.respond_to?(:of_type)

        unwrap(type.of_type)
      end
    end
  end
end

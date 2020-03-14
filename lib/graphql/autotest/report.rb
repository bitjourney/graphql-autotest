module GraphQL
  module Autotest
    class Report < Struct.new(:executions, keyword_init: true)
      Execution = Struct.new(:query, :result, keyword_init: true) do
        def query_summary
          query.lines[1].strip
        end

        def to_error_message
          query_summary + "\n" + result['errors'].inspect
        end
      end

      def error?
        !errored_executions.empty?
      end

      def errored_executions
        executions.select { |e| e.result['errors'] }
      end

      def raise_if_error!
        raise errored_executions.map(&:to_error_message).join("\n\n") if error?
      end
    end
  end
end

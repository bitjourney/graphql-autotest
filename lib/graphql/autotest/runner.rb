module GraphQL
  module Autotest
    class Runner
      attr_reader :schema, :context, :arguments_fetcher, :max_depth, :skip_if
      private :schema, :context, :arguments_fetcher, :max_depth, :skip_if

      # @param schema [Class<GraphQL::Schema>]
      # @param context [Hash] it passes to GraphQL::Schema.execute
      # @param arguments_fetcher [Proc] A proc receives a field and ancestors keyword argument, and it returns a Hash. The hash is passed to call the field.
      # @param max_depth [Integer] Max query depth. It is recommended to specify to avoid too large query.
      # @param skip_if [Proc] A proc receives a field and ancestors keyword argument, and it returns a boolean. If it returns ture, the field is skipped.
      def initialize(schema:, context:, arguments_fetcher: ArgumentsFetcher::DEFAULT, max_depth: Float::INFINITY, skip_if: -> (_field, **) { false })
        @schema = schema
        @context = context
        @arguments_fetcher = arguments_fetcher
        @max_depth = max_depth
        @skip_if = skip_if
      end

      def report(dry_run: false)
        report = Report.new(executions: [])

        fields = QueryGenerator.generate(
          # FIXME
          document: schema.to_document,
          arguments_fetcher: arguments_fetcher,
          max_depth: max_depth,
          skip_if: skip_if,
        )
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

      def report!(dry_run: false)
        report(dry_run: dry_run).tap do |r|
          r.raise_if_error!
        end
      end
    end
  end
end

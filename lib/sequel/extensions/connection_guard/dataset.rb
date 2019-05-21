# frozen_string_literal: true

module Sequel
  module ConnectionGuard
    # A value object that stores all the information required to construct a Sequel dataset.
    #
    # @api private
    # @since 0.1.0
    class Dataset
      # @api private
      # @since 0.1.0
      attr_reader :connection_guard, :table_name

      # @param connection_guard [Sequel::ConnectionGuard::ConnectionGuard]
      # @param table_name [Symbol]
      #
      # @api private
      # @since 0.1.0
      def initialize(connection_guard, table_name)
        @connection_guard = connection_guard
        @table_name = table_name
      end
    end
  end
end

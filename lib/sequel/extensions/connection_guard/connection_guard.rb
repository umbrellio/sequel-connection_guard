# frozen_string_literal: true

module Sequel
  module ConnectionGuard
    # @api private
    # @since 0.1.0
    class ConnectionGuard
      # @param config [String, Hash] database configuration
      # @param initializer [Proc] code to run upon successful connection
      #
      # @api private
      # @since 0.1.0
      def initialize(config, &initializer)
        @config = config
        @initializer = initializer
        @connection = nil

        try_establish_connection
      end

      # @raise [Sequel::DatabaseConnectionError] connection failure
      #
      # @api private
      # @since 0.1.0
      def force_execute(&_block)
        try_establish_connection if @connection.nil?
        raise Sequel::DatabaseConnectionError unless connection_established?

        yield @connection
      end

      # @raise [Sequel::DatabaseConnectionError] if connection is not established
      #
      # @api private
      # @since 0.1.0
      def raw_handle
        try_establish_connection if @connection.nil?

        return @connection if connection_established?
        raise Sequel::DatabaseConnectionError
      end

      private

      # @return [void]
      #
      # @api private
      # @since 0.1.0
      def try_establish_connection
        @connection = Sequel.connect(@config)
        @initializer&.call(@connection)
      rescue Sequel::DatabaseConnectionError
      end

      # @return [bool]
      #
      # @api private
      # @since 0.1.0
      def connection_established?
        return false if @connection.nil?
        @connection.test_connection
      rescue Sequel::Error
        false
      end
    end
  end
end

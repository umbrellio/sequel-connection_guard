# frozen_string_literal: true

module Sequel
  module ConnectionGuard
    # An abstraction for safely accessing Sequel models.
    #
    # @example Creating a database guard
    #   DB = Sequel::DatabaseGuard.new('postgres://localhost/mydb')
    #
    # @example Safely accessing the database
    #   users = DB.safe_execute do
    #     alive do |db|
    #       db[:users].all
    #     end
    #
    #     dead do
    #       []
    #     end
    #   end
    #
    # @example Unsafely accessing the database (raises an exception if connection fails)
    #   DB.force_execute { |db| db[:users].insert(email: 'billikota@example.com', role: 'admin') }
    #
    # @api public
    # @since 0.1.0
    class DatabaseGuard
      # @param config [String, Hash] database configuration
      # @param initializer [Proc] code to run upon successful connection
      #
      # @api public
      # @since 0.1.0
      def initialize(config, &initializer)
        @connection_guard = ConnectionGuard.new(config, &initializer)
      end

      # Safely access the database.
      #
      # @example
      #   users = DB.safe_execute do
      #     alive { |db| db[:users].all }
      #     dead { [] }
      #   end
      #
      # @param block [Proc]
      #
      # @api public
      # @since 0.1.0
      def safe_execute(&block)
        executor = Executor.new
        executor.instance_eval(&block)
        @connection_guard.force_execute(&executor.on_alive)
      rescue Sequel::DatabaseConnectionError
        executor.on_dead&.call
      end

      # Unsafely access the database. Will fail if connection fails.
      #
      # @example
      #   DB.force_execute { |db| db[:users].insert(email: 'rustam@example.com') }
      #
      # @param block [Proc]
      # @raise [Sequel::DatabaseConnectionError] connection failure
      #
      # @api public
      # @since 0.1.0
      def force_execute(&block)
        @connection_guard.force_execute(&block)
      end

      # A raw connection handle. Intended for use in test environments (e.x. with DatabaseCleaner)
      #
      # @api public
      # @since 0.1.0
      def raw_handle
        @connection_guard.raw_handle
      end

      # @param table_name [Symbol]
      # @return [Sequel::ConnectionGuard::Dataset]
      #
      # @api private
      # @since 0.1.0
      def [](table_name)
        Dataset.new(@connection_guard, table_name)
      end

      # @return [void]
      #
      # @api private
      # @since 0.1.0
      def disconnect
        @connection_guard.force_execute(&:disconnect)
      end
    end
  end
end

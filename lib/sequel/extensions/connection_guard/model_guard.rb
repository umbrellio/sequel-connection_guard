# frozen_string_literal: true

module Sequel
  module ConnectionGuard
    # An abstraction for safely accessing Sequel models.
    #
    # @see Sequel.ModelGuard
    #
    # @api public
    # @since 0.1.0
    class ModelGuard
      # @param ds [Sequel::ConnectionGuard::Dataset]
      # @option class_body [Proc]
      #
      # @api private
      # @since 0.1.0
      def initialize(ds, &class_body)
        @connection_guard = ds.connection_guard
        @table_name = ds.table_name
        @class_body = class_body
        @connected = false
        @model = nil
      end

      # Safely access the model.
      #
      # @example
      #   users = UserGuard.safe_execute do
      #     alive { |model| model.all }
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

        @connection_guard.force_execute do |connection|
          instantiate_model(connection) unless @connected

          executor.on_alive.call(@model)
        end
      rescue Sequel::DatabaseConnectionError
        @connected = false

        executor.on_dead&.call
      end

      # Unsafely access the model. Will fail if connection fails.
      #
      # @example
      #   UserGuard.force_execute { |model| model.create(email: 'vova@example.com') }
      #
      # @param block [Proc]
      # @raise [Sequel::DatabaseConnectionError] connection failure
      #
      # @api public
      # @since 0.1.0
      def force_execute(&block)
        @connection_guard.force_execute do |connection|
          instantiate_model(connection) unless @connected

          yield @model
        end
      rescue Sequel::DatabaseConnectionError => error
        @connected = false
        raise error
      end

      # @api private
      # @since 0.1.0
      def raw_model
        try_instantiate_model if @model.nil?
        @model
      end

      private

      # @raise [Sequel::DatabaseConnectionError] connection failure
      #
      # @api private
      # @since 0.1.0
      def instantiate_model(connection)
        if @model.nil?
          @model = Class.new(Sequel::Model(connection[@table_name])).tap do |klass|
            klass.class_eval(&@class_body) unless @class_body.nil?
          end
        else
          @model.dataset = connection[@table_name]
        end

        @connected = true
      end

      # @api private
      # @since 0.1.0
      def try_instantiate_model
        @connection_guard.force_execute { |connection| instantiate_model(connection) }
      rescue Sequel::DatabaseConnectionError
      end
    end
  end
end

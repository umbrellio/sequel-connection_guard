# frozen_string_literal: true

module Sequel
  module ConnectionGuard
    # Provides a DSL for accessing the database safely.
    #
    # @example Safely accessing a database
    #   DB.safe_execute do
    #     alive do |db|
    #       db[:users].all
    #     end
    #
    #     dead do
    #       []
    #     end
    #   end
    #
    # @example Safely accessing a model
    #   UserGuard.safe_execute do
    #     alive do |model|
    #       model.first!
    #     end
    #
    #     # `dead` handler is optional
    #   end
    #
    # @api private
    # @since 0.1.0
    class Executor
      # @api private
      # @since 0.1.0
      attr_reader :on_dead

      # @param block [Proc]
      #
      # @api private
      # @since 0.1.0
      def alive(&block)
        @on_alive = block
      end

      # @param block [Proc]
      #
      # @api private
      # @since 0.1.0
      def dead(&block)
        @on_dead = block
      end

      # @raise [Sequel::ConnectionGuard::ConfigurationError] if an `alive` handler is missing
      #
      # @api private
      # @since 0.1.0
      def on_alive
        raise ConfigurationError, '`alive` handler is required!' if @on_alive.nil?
        @on_alive
      end
    end
  end
end

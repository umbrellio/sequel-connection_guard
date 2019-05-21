# frozen_string_literal: true

require 'sequel/extensions/connection_guard/configuration_error'
require 'sequel/extensions/connection_guard/connection_guard'
require 'sequel/extensions/connection_guard/database_guard'
require 'sequel/extensions/connection_guard/dataset'
require 'sequel/extensions/connection_guard/executor'
require 'sequel/extensions/connection_guard/model_guard'

# @api public
# @since 0.1.0
module Sequel
  # A constructor for model guards.
  #
  # @param ds [Sequel::ConnectionGuard::Dataset]
  # @param class_body [Proc] Mimics Sequel::Model class body.
  #
  # @example Creating model guards
  #   DB = Sequel::DatabaseGuard.new('postgres://localhost/mydb')
  #
  #   UserGuard = Sequel::ModelGuard(DB[:users]) do
  #     many_to_one :cookies, class: 'CookieGuard::RawModel', key: :user_id
  #
  #     def admin?
  #       role == 'admin'
  #     end
  #   end
  #
  #   CookieGuard = Sequel::ModelGuard(DB[:cookies])
  #
  # @example Safely accessing a model
  #   users = UserGuard.safe_execute do
  #     alive do |model|
  #       model.all
  #     end
  #
  #     dead do
  #       []
  #     end
  #   end
  #
  # @example Unsafely accessing a model (raises an exception if connection fails)
  #   cookies = UserGuard.force_execute { |model| model.first!(id: id).cookies }
  #
  # @api public
  # @since 0.1.0
  # rubocop:disable Naming/MethodName
  def self.ModelGuard(ds, &class_body)
    model = ConnectionGuard::ModelGuard.new(ds, &class_body)

    Class.new.tap do |klass|
      klass.define_singleton_method(:safe_execute) do |&block|
        model.safe_execute(&block)
      end

      klass.define_singleton_method(:force_execute) do |&block|
        model.force_execute(&block)
      end

      model.register_interface(klass)
    end
  end
  # rubocop:enable Naming/MethodName

  # @see Sequel::ConnectionGuard::DatabaseGuard
  #
  # @api public
  # @since 0.1.0
  DatabaseGuard = ConnectionGuard::DatabaseGuard

  # @api public
  # @since 0.1.0
  module ConnectionGuard; end
end

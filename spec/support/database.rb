# frozen_string_literal: true

require_relative "database_helper.rb"

Sequel.extension :migration
Sequel.extension :connection_guard

::DB_HELPER ||= DatabaseHelper.new

# frozen_string_literal: true

class DatabaseHelper
  DATABASE_URL = ENV["DB_URL"] || "postgres://localhost/sequel_connection_guard"

  def initialize(handle)
    @handle = handle
    @connections = []
    @max_connections = handle.force_execute do |db|
      db.fetch("SHOW max_connections").first.fetch(:max_connections).to_i
    end
  end

  def turn_on
    connections.each(&:disconnect)
    @connections = []
  end

  def turn_off
    handle.disconnect
    max_connections.times { connections << Sequel.connect(DATABASE_URL) }
  rescue Sequel::DatabaseConnectionError
  end

  def migrate_up
    handle.force_execute { |db| Sequel::TimestampMigrator.new(db, "spec/fixtures/migrations").run }
  end

  def migrate_down
    handle.force_execute do |db|
      db.tables.each { |t| db.drop_table?(t, cascade: true) }
    end
  end

  def clear
    handle.force_execute do |db|
      db.tables.each { |t| db.run("DELETE FROM #{t} WHERE true") }
    end
  end

  private

  attr_reader :handle, :max_connections
  attr_accessor :connections
end

# frozen_string_literal: true

require "simplecov"
require "coveralls"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
])

SimpleCov.minimum_coverage(100)

SimpleCov.start do
  add_filter "spec/"
end

require "bundler/setup"
require "sequel"
require "pry"

require_relative "support/database.rb"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) { DB_HELPER.migrate_up }

  config.after(:example) { DB_HELPER.clear }

  config.after(:suite) { DB_HELPER.migrate_down }
end

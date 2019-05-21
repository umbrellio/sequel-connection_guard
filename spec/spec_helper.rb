# frozen_string_literal: true

if ENV["COVER"]
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
end

require "bundler/setup"
require "sequel"

Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:example) do
    DB.force_execute { |db| Sequel::TimestampMigrator.new(db, "spec/fixtures/migrations").run }
  end

  config.after(:example) { DB_HELPER.clear }
end

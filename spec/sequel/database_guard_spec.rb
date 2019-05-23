# frozen_string_literal: true

RSpec.describe Sequel::DatabaseGuard do
  let(:db_guard) { Sequel::DatabaseGuard.new(DatabaseHelper::DATABASE_URL) }

  def turn_database_off!
    db_guard.disconnect
    DB_HELPER.turn_off
  end

  describe "#safe_execute" do
    context "database is up" do
      before do
        db_guard.safe_execute do
          alive { |db| db[:users].insert(email: "shabolda@example.com", password: "12345") }
        end
      end

      it "throws a configuration error if no `alive` handler is provided" do
        expect do
          db_guard.safe_execute {}
        end.to raise_error(
          Sequel::ConnectionGuard::ConfigurationError,
          "`alive` handler is required for .safe_execute",
        )
      end

      it "runs queries" do
        users = db_guard.safe_execute do
          alive { |db| db[:users].all }
        end

        expect(users).to contain_exactly(
          a_hash_including(
            email: "shabolda@example.com", password: "12345",
          ),
        )
      end

      it "reconnects when possible" do
        turn_database_off!

        result = db_guard.safe_execute do
          alive { |db| db[:users].all }
          dead { "error" }
        end

        expect(result).to eq("error")

        DB_HELPER.turn_on

        result = db_guard.safe_execute do
          alive { |db| db[:users].all }
        end

        expect(result).to contain_exactly(
          a_hash_including(
            email: "shabolda@example.com", password: "12345",
          ),
        )
      end
    end

    context "database is down" do
      before { DB_HELPER.turn_off }

      after { DB_HELPER.turn_on }

      it "does nothing if no `dead` handler is specified" do
        expect do
          db_guard.safe_execute do
            alive { |db| db[:users].all }
          end
        end.not_to raise_error
      end

      it "invokes `dead` handler if specified" do
        result = db_guard.safe_execute do
          alive { |db| db[:users].all }

          dead { "connection failure" }
        end

        expect(result).to eq("connection failure")
      end

      it "does not invoke `alive` handler" do
        alive_spy = spy

        db_guard.safe_execute do
          alive { |_| alive_spy.call }
        end

        expect(alive_spy).not_to have_received(:call)
      end
    end
  end

  describe "#force_execute" do
    context "database is up" do
      before do
        db_guard.force_execute do |db|
          db[:users].insert(email: "shabolda@example.com", password: "12345")
        end
      end

      it "executes the query" do
        result = db_guard.force_execute { |db| db[:users].first }
        expect(result).to include(email: "shabolda@example.com", password: "12345")
      end

      it "reconnects when possible" do
        turn_database_off!

        expect do
          db_guard.force_execute { |db| db[:users].all }
        end.to raise_error(Sequel::DatabaseConnectionError)

        DB_HELPER.turn_on

        result = db_guard.force_execute { |db| db[:users].all }

        expect(result).to contain_exactly(
          a_hash_including(
            email: "shabolda@example.com", password: "12345",
          ),
        )
      end
    end

    context "database is down" do
      before { DB_HELPER.turn_off }

      after { DB_HELPER.turn_on }

      it "fails to connect" do
        expect do
          db_guard.force_execute { |db| db[:users].all }
        end.to raise_error(Sequel::DatabaseConnectionError)
      end

      it "reconnects when possible" do
        expect(db_guard).not_to be_nil

        expect do
          db_guard.force_execute { |db| db[:users].all }
        end.to raise_error(Sequel::DatabaseConnectionError)

        DB_HELPER.turn_on

        expect do
          db_guard.force_execute { |db| db[:users].all }
        end.not_to raise_error
      end
    end
  end

  describe "#raw_handle" do
    let(:handle) { db_guard.raw_handle }

    context "database is up" do
      it "returns a raw connection handle" do
        expect(handle[:users].count).to eq(0)
      end
    end

    context "database is down" do
      before { DB_HELPER.turn_off }

      after { DB_HELPER.turn_on }

      specify do
        expect { handle }.to raise_error(Sequel::DatabaseConnectionError)
      end
    end
  end
end

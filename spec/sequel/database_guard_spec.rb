# frozen_string_literal: true

RSpec.describe Sequel::DatabaseGuard do
  describe "#safe_execute" do
    context "database is up" do
      before do
        DB.safe_execute do
          alive { |db| db[:users].insert(email: "shabolda@example.com", password: "12345") }
        end
      end

      it "throws a configuration error if no `alive` handler is provided" do
        expect do
          DB.safe_execute {}
        end.to raise_error(
          Sequel::ConnectionGuard::ConfigurationError,
          "`alive` handler is required for .safe_execute",
        )
      end

      it "runs queries" do
        users = DB.safe_execute do
          alive { |db| db[:users].all }
        end

        expect(users).to contain_exactly(
          a_hash_including(
            email: "shabolda@example.com", password: "12345",
          ),
        )
      end

      it "reconnects when possible" do
        DB_HELPER.turn_off

        result = DB.safe_execute do
          alive { |db| db[:users].all }
          dead { "error" }
        end

        expect(result).to eq("error")

        DB_HELPER.turn_on

        result = DB.safe_execute do
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
          DB.safe_execute do
            alive { |db| db[:users].all }
          end
        end.not_to raise_error
      end

      it "invokes `dead` handler if specified" do
        result = DB.safe_execute do
          alive { |db| db[:users].all }

          dead { "connection failure" }
        end

        expect(result).to eq("connection failure")
      end

      it "does not invoke `alive` handler" do
        alive_spy = spy

        DB.safe_execute do
          alive { |_| alive_spy.call }
        end

        expect(alive_spy).not_to have_received(:call)
      end
    end
  end

  describe "#force_execute" do
    context "database is up" do
      before do
        DB.force_execute do |db|
          db[:users].insert(email: "shabolda@example.com", password: "12345")
        end
      end

      it "executes the query" do
        result = DB.force_execute { |db| db[:users].first }
        expect(result).to include(email: "shabolda@example.com", password: "12345")
      end

      it "reconnects when possible" do
        DB_HELPER.turn_off

        expect do
          DB.force_execute { |db| db[:users].all }
        end.to raise_error(Sequel::DatabaseConnectionError)

        DB_HELPER.turn_on

        result = DB.force_execute { |db| db[:users].all }

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
          DB.force_execute { |db| db[:users].all }
        end.to raise_error(Sequel::DatabaseConnectionError)
      end
    end
  end

  describe "#raw_handle" do
    let(:handle) { DB.raw_handle }

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

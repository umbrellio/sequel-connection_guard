# frozen_string_literal: true

RSpec.describe "model guard" do
  let(:db_guard) { Sequel::DatabaseGuard.new(DatabaseHelper::DATABASE_URL) }

  let(:user_guard) do
    Sequel::ModelGuard(db_guard[:users]) do
      one_to_many :cookies, class: "Cookie::RawModel", key: :user_id

      def to_s
        "#{email} #{password}"
      end
    end
  end

  let(:cookie_guard) do
    Sequel::ModelGuard(db_guard[:cookies]) do
      many_to_one :user
    end
  end

  def turn_database_off!
    db_guard.disconnect
    DB_HELPER.turn_off
  end

  before do
    stub_const("User", user_guard)
    stub_const("Cookie", cookie_guard)
  end

  describe "#safe_execute" do
    context "database is up" do
      before do
        user = User.safe_execute do
          alive do |model|
            model.create(email: "shabolda@example.com", password: "12345")
          end
        end

        Cookie.safe_execute do
          alive do |model|
            model.create(user_id: user.id, value: "kek")
            model.create(user_id: user.id, value: "pek")
          end
        end
      end

      it "throws a configuration error if no `alive` handler is provided" do
        expect do
          User.safe_execute {}
        end.to raise_error(
          Sequel::ConnectionGuard::ConfigurationError,
          "`alive` handler is required for .safe_execute",
        )
      end

      it "runs queries" do
        users = User.safe_execute do
          alive(&:all)
        end

        expect(users).to contain_exactly(
          an_object_having_attributes(
            email: "shabolda@example.com",
            password: "12345",
          ),
        )
      end

      it "reconnects when possible" do
        turn_database_off!

        result = User.safe_execute do
          alive(&:all)
          dead { "error" }
        end

        expect(result).to eq("error")

        DB_HELPER.turn_on

        result = User.safe_execute do
          alive(&:all)
        end

        expect(result).to contain_exactly(
          an_object_having_attributes(
            email: "shabolda@example.com", password: "12345",
          ),
        )
      end

      specify "model attributes and methods work" do
        user = User.safe_execute do
          alive(&:first!)
        end

        expect(user.to_s).to eq("shabolda@example.com 12345")
        expect(user.cookies).to contain_exactly(
          an_object_having_attributes(value: "kek"),
          an_object_having_attributes(value: "pek"),
        )
      end
    end

    context "database is down" do
      before { turn_database_off! }

      after { DB_HELPER.turn_on }

      it "does nothing if no `dead` handler is specified" do
        result = User.safe_execute do
          alive(&:all)
        end
        expect(result).to be_nil
      end

      it "invokes `dead` handler if specified" do
        result = User.safe_execute do
          alive(&:all)

          dead { "kekpek" }
        end

        expect(result).to eq("kekpek")
      end

      it "does not invoke `alive` handler" do
        alive_spy = spy

        User.safe_execute do
          alive { |_| alive_spy.call }
        end

        expect(alive_spy).not_to have_received(:call)
      end
    end
  end

  describe "#force_execute" do
    context "database is up" do
      before do
        User.force_execute do |model|
          model.create(email: "shabolda@example.com", password: "12345")
        end
      end

      it "executes the query" do
        result = User.force_execute(&:first!)
        expect(result).to include(email: "shabolda@example.com", password: "12345")
      end

      it "reconnects when possible" do
        turn_database_off!

        expect do
          User.force_execute(&:all)
        end.to raise_error(Sequel::DatabaseConnectionError)

        DB_HELPER.turn_on

        result = User.force_execute(&:all)

        expect(result).to contain_exactly(
          an_object_having_attributes(
            email: "shabolda@example.com", password: "12345",
          ),
        )
      end
    end

    context "database is down" do
      before { turn_database_off! }

      after { DB_HELPER.turn_on }

      it "fails to connect" do
        expect(User).not_to be_nil

        expect do
          User.force_execute(&:all)
        end.to raise_error(Sequel::DatabaseConnectionError)
      end
    end
  end

  describe "::RawModel" do
    context "connection is up" do
      it "returns the model" do
        expect(User::RawModel.ancestors).to include(Sequel::Model)
      end

      it "behaves normally if constant is missing" do
        expect { User::Ololo }.to raise_error(NameError, "uninitialized constant User::Ololo")
      end

      context "connection lost" do
        after { DB_HELPER.turn_on }

        it "returns the model without connection" do
          expect(User::RawModel.ancestors).to include(Sequel::Model)

          turn_database_off!

          expect(User::RawModel.ancestors).to include(Sequel::Model)
          expect { User::RawModel.all }.to raise_error(Sequel::DatabaseConnectionError)
        end

        context "connection is back up" do
          it "reconnects the model" do
            expect(User::RawModel.all).to eq([])
          end
        end
      end
    end

    context "connection is down" do
      before do
        turn_database_off!

        NewUser ||= Sequel::ModelGuard(db_guard[:users])
      end

      after { DB_HELPER.turn_on }

      it "returns nil" do
        expect(NewUser::RawModel).to be_nil
      end

      context "connection is back up" do
        before { DB_HELPER.turn_on }

        it "returns a functional model" do
          expect(NewUser::RawModel.all).to eq([])
        end
      end
    end
  end
end

# frozen_string_literal: true

Sequel.migration do
  up do
    ::DB.force_execute do |db|
      db.create_table :cookies do
        primary_key :id
        column :user_id, :bigint
        column :value, :text
      end
    end
  end

  down do
    ::DB.force_execute { |db| db.drop_table :cookies }
  end
end

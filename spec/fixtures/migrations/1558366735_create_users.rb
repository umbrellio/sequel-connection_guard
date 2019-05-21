# frozen_string_literal: true

Sequel.migration do
  up do
    ::DB.force_execute do |db|
      db.create_table :users do
        primary_key :id
        column :email, :text
        column :password, :text
      end
    end
  end

  down do
    ::DB.force_execute { |db| db.drop_table :users }
  end
end

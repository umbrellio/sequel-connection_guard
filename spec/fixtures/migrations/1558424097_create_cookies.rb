# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :cookies do
      primary_key :id
      column :user_id, :bigint
      column :value, :text
    end
  end

  down do
    drop_table :cookies
  end
end

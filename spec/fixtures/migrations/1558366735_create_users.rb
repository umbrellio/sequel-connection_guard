# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :users do
      primary_key :id
      column :email, :text
      column :password, :text
    end
  end

  down do
    drop_table :users
  end
end

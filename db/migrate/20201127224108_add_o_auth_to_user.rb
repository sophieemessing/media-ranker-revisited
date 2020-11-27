class AddOAuthToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :name, :string
    add_column :users, :email, :string
    add_column :users, :uid, :integer
    add_column :users, :provider, :string
  end
end

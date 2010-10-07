class AddDbInfoActivity < ActiveRecord::Migration
  def self.up
    add_column :activities, :db_type, :string
    add_column :activities, :dev_schema, :string
    add_column :activities, :dev_user, :string
    add_column :activities, :dev_password, :string
  end

  def self.down
    remove_column :activities, :db_type
    remove_column :activities, :dev_schema
    remove_column :activities, :dev_user
    remove_column :activities, :dev_password
  end
end

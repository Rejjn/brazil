class AddWipeableToDbInstance < ActiveRecord::Migration
  def self.up
    add_column :db_instances, :wipeable_schemas, :boolean
  end

  def self.down
    remove_column :db_instances, :wipeable_schemas
  end
end

class MoveToOneDbInstance < ActiveRecord::Migration
  def self.up
    add_column :activities, :db_instance_id, :string
    drop_table :db_instance_activities
  end

  def self.down
    remove_column :activities, :db_instance_id
  end
end

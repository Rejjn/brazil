class DropDbDeploys < ActiveRecord::Migration
  def self.up
    drop_table :db_deploys
  end

  def self.down
  end
end

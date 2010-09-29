class CreateDbDeploys < ActiveRecord::Migration
  def self.up
    create_table :db_deploys do |t|
      t.references :db_instance
      t.string :src_type
      t.string :src_path
      t.string :current_version

      t.timestamps
    end
  end

  def self.down
    drop_table :db_deploys
  end
end

class RefactorVersions < ActiveRecord::Migration
  def self.up
    change_column :versions, :state, :integer
    drop_table :db_instance_versions
  end

  def self.down
    change_column :versions, :state, :string
    create_table :db_instance_versions, :id => false do |t|
      t.references :db_instance
      t.references :version
    end
  end
end

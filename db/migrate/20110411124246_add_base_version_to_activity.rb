class AddBaseVersionToActivity < ActiveRecord::Migration
  def self.up
    add_column :activities, :base_version, :string
  end

  def self.down
    remove_column :activities, :base_version
  end
end

class RemoveDbaFromChange < ActiveRecord::Migration
  def self.up
    remove_column :changes, :dba
  end

  def self.down
    add_column :changes, :dba, :string
  end
end

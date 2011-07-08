class FixDbTypes < ActiveRecord::Migration
  def self.up
    Activity.all.each do |activity|
      case activity.db_type
        when 'MySQL'
          activity.update_attribute(:db_type, DbInstance::TYPE_MYSQL)
        when 'Oracle8'
          activity.update_attribute(:db_type, DbInstance::TYPE_ORACLE)
      end
    end
    
    DbInstance.all.each do |instance|
      case instance.db_type
        when 'MySQL'
          instance.update_attribute(:db_type, DbInstance::TYPE_MYSQL)
        when 'Oracle8'
          instance.update_attribute(:db_type, DbInstance::TYPE_ORACLE)
      end
    end
  end

  def self.down
  end
end


class Change < ActiveRecord::Base
  STATE_SAVED = 'saved'
  STATE_EXECUTED = 'executed'

  belongs_to :activity
  validates_presence_of :sql

  before_save :check_correct_state, :mark_activity_updated

  def self.activity_sql(activity_id)
    Change.all(:order => 'created_at ASC', :conditions => {:activity_id => activity_id, :state => [Change::STATE_EXECUTED, Change::STATE_SAVED]}).collect {|change| change.sql}.join("\n")
  end

  def use_sql(sql, db_username, db_password)
    case state
    when STATE_EXECUTED
      db_tools = Brazil::DatabaseSchema.new
      db_tools.configure(db_instance_dev.host, db_instance_dev.port, db_instance_dev.db_type, activity.dev_schema, activity.dev_user, activity.dev_password)
      sql = db_tools.prepare_sql(db_instance_dev.db_type, sql, activity.dev_schema, activity.dev_schema, activity.dev_schema)
      db_tools.execute_sql(sql)
    when STATE_SAVED
      #unless db_instance_dev.check_db_credentials(db_username, db_password, activity.dev_schema)
      #  errors.add_to_base("You don't have the Database credentials to save this change")
      #  return false, sql
      #end
    else
      raise Brazil::UnknowStateException, "Unknown state for Change when trying to execute SQL, #{self}"
    end

    return true, sql
  rescue Brazil::DBException => exception
    errors.add(:sql, "not executed: #{exception.to_s}")
    return false, exception.data
  end

  def to_s
    "change ##{id.to_s}"
  end

  private

  def db_instance_dev
    return activity.db_instance if activity.db_instance.dev?
    raise Brazil::NoDBInstanceException, "#{activity} has no #{DbInstance::ENV_DEV} database instance set. Use Edit Activity to set one."
  end

  def check_correct_state
    unless activity.development?
      errors.add_to_base("You can only add or update a change when its activity is in state development")
      false
    end
  end

  def mark_activity_updated
    activity.update_attribute(:updated_at, Time.now)
  end
end

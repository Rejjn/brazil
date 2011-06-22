
class Change < ActiveRecord::Base
  STATE_SAVED = 'saved'
  STATE_EXECUTED = 'executed'

  belongs_to :activity
  validates_presence_of :sql

  before_save :check_correct_state, :mark_activity_updated

  def self.activity_sql(activity_id)
    Change.all(:order => 'created_at ASC', :conditions => {:activity_id => activity_id, :state => [Change::STATE_EXECUTED, Change::STATE_SAVED]}).collect {|change| change.sql}.join("\n\n")
  end

  def self.activity_suggested_rollback_sql(activity_id)
    activity = Activity.find(activity_id)
    update_sql = Change.all(:order => 'created_at ASC', :conditions => {:activity_id => activity_id, :state => [Change::STATE_EXECUTED, Change::STATE_SAVED]}).collect {|change| change.sql}.join("\n\n")
    activity.db_instance_dev.suggest_rollback_sql update_sql
  end
  
  def execute
    prepared_sql = [{:source => to_s, :sql => sql}]
    run_successfull, deployment_results = db_instance_dev.execute_sql(prepared_sql, activity.dev_user, activity.dev_password, activity.dev_schema)
    update_attribute(:state, STATE_EXECUTED)
    
    [run_successfull, deployment_results]
  end

  def to_s
    "change ##{id.to_s}"
  end

  private

  def db_instance_dev
    return activity.db_instance if activity.db_instance && activity.db_instance.dev?
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

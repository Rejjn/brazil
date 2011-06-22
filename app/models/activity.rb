class Activity < ActiveRecord::Base
  STATE_DEVELOPMENT = 'development'
  STATE_VERSIONED = 'versioned'
  STATE_DEPLOYED = 'deployed'

  belongs_to :app
  belongs_to :db_instance
  
  has_many :versions, :dependent => :destroy
  has_many :changes, :order => "created_at ASC", :dependent => :destroy

  validates_associated :db_instance
  validates_presence_of :name, :schema, :db_type, :dev_schema, :dev_user, :dev_password, :base_version

  # FIXME: Add before_save check state

  scope :latest, lambda { |limit| {:order => 'updated_at DESC', :limit => limit} }

  def development!
    update_attribute(:state, STATE_DEVELOPMENT)
  end

  def development?
    (state == Activity::STATE_DEVELOPMENT)
  end

  def versioned?
    (state == Activity::STATE_VERSIONED)
  end

  def versioned!
    update_attribute(:state, STATE_VERSIONED)
  end

  def deployed!
    update_attribute(:state, STATE_DEPLOYED)
  end

  def vc_path
    "#{app.vc_path}/#{schema}/#{db_type.downcase}"
  end

  def execute
    begin
      current_versions = db_instance_dev.deployed_versions(dev_user, dev_password, dev_schema)
      unless current_versions.last.to_s == base_version
        db_instance_dev.deploy_update(app, schema, dev_user, dev_password, dev_schema, base_version)
      end
      
      sql = []
      changes.each do |change|
        sql << {:source => change.to_s, :sql => change.sql, :change => change}
      end
  
      run_successfull, deployment_results = db_instance_dev.execute_sql(sql, dev_user, dev_password, dev_schema)
     
      deployment_results.each do |result|
        result[:sql_script][:change].update_attribute(:state, Change::STATE_EXECUTED) if result[:run]
      end
      
      return [run_successfull, deployment_results]
    rescue => e
      raise 
    end
  end

  def reset
    db_instance.wipe_schema(dev_user, dev_password, dev_schema)    
    db_instance.deploy_update(app, schema, dev_user, dev_password, dev_schema, base_version)
    
    changes.each do |change|
      change.update_attribute(:state, Change::STATE_SAVED)
    end
    
  end

  def to_s
    name
  end
  
  def db_instance_dev
    return db_instance if db_instance && db_instance.dev?
    raise Brazil::NoDBInstanceException, "#{self} has no #{DbInstance::ENV_DEV} database instance set. Use Edit Activity to set one."
  end
  
end

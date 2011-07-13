
class Version < ActiveRecord::Base
  STATE_CREATED = 1
  STATE_UPDATE_TESTED = 2
  STATE_ROLLBACK_TESTED = 4
  STATE_UPLOADED = 8
  STATE_DEPLOYED = 16

  belongs_to :activity
  belongs_to :db_instance

  validates_presence_of :update_sql, :rollback_sql, :schema_version
  validates_inclusion_of :create_schema_version, :in => [true, false]

  #before_save :check_no_duplicate_schema_db,
  before_save :update_activity_state
  before_destroy :check_version_destroy_state

  before_create do 
    state = STATE_CREATED
  end

  def test_update(test_db_instance, test_db_schema, test_db_username, test_db_password)
    test_db_instance = DbInstance.find(test_db_instance) unless test_db_instance.class == DbInstance 

    sql = SqlController.new.update_sql self
    results =  test_db_instance.execute_sql(sql, test_db_username, test_db_password, test_db_schema)
    
    if results[0]
      update_tested! 
    else 
      update_tested! true
    end
    
    return results
  rescue Brazil::DBException => db_exception
    update_tested! true
    errors.add(:base, "SQL: #{db_exception}")
    return db_exception.data
  end


  def test_rollback(test_db_instance, test_db_schema, test_db_username, test_db_password)
    test_db_instance = DbInstance.find(test_db_instance) unless test_db_instance.class == DbInstance 

    sql = SqlController.new.rollback_sql self
    results =  test_db_instance.execute_sql(sql, test_db_username, test_db_password, test_db_schema)
    
    if results[0]
      rollback_tested! 
    else 
      rollback_tested! true
    end
    
    return results
  rescue Brazil::DBException => db_exception
    rollback_tested! true
    errors.add(:base, "SQL: #{db_exception}")
    return db_exception.data
  end

  def set_schema_version major, minor, patch
    begin
      next_schema_version = Brazil::SchemaRevision.new(major, minor, patch) 
      asvc = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => activity.app.vc_path, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
      raise AppSchemaVersionControlException, 'That version is not a valid next version for that schema!' unless asvc.valid_next_version? activity.schema, next_schema_version
    rescue => exception
      unless exception.to_s =~ /reason_phrase=\"Not Found\"/ 
        errors.add(:base, "Could not lookup version for schema '#{schema}' (#{exception})")
        return
      end
    end
    
    if next_schema_version.to_s == '1_0_0' 
      self.create_schema_version = true
    else
      self.create_schema_version = false
    end
    
    self.schema_version = next_schema_version.to_s
  end

  def initial_version?
    (schema_version.to_s == '1_0_0')
  end

  def merge_to_dev(update_sql, dev_db_instance_id, dev_schema, db_username, db_password)
    DbInstance.find(dev_db_instance_id).execute_sql(update_sql, db_username, db_password, dev_schema)
  rescue ActiveRecord::RecordNotFound
    errors.add(:base, "Can not find db instance with id: #{dev_db_instance_id}")
  rescue Brazil::DBException => db_exception
    errors.add(:base, "SQL: #{db_exception}")
  end

  def schema_revision
    Brazil::SchemaRevision.from_string(schema_version)
  end

  def created! unset_flag = false
    unless unset_flag
      update_attribute(:state, (state | STATE_CREATED))
    else
      update_attribute(:state, (state ^ STATE_CREATED))
    end
  end

  def created?
    (state & STATE_CREATED) != 0
  end

  def update_tested! unset_flag = false
    unless unset_flag
      update_attribute(:state, (state | STATE_UPDATE_TESTED))
    else 
      update_attribute(:state, (state ^ STATE_UPDATE_TESTED)) if update_tested?
    end
  end

  def update_tested?
    (state & STATE_UPDATE_TESTED) != 0
  end

  def rollback_tested! unset_flag = false
    unless unset_flag
      update_attribute(:state, (state | STATE_ROLLBACK_TESTED))
    else
      update_attribute(:state, (state ^ STATE_ROLLBACK_TESTED)) if rollback_tested?
    end
  end

  def rollback_tested?
    (state & STATE_ROLLBACK_TESTED) != 0
  end

  def tested?
    (state & STATE_ROLLBACK_TESTED) != 0 && (state & STATE_UPDATE_TESTED) != 0 
  end

  def uploaded! unset_flag = false
    unless unset_flag
      update_attribute(:state, (state | STATE_UPLOADED))
    else
      update_attribute(:state, (state ^ STATE_UPLOADED)) if uploaded?
    end
  end

  def uploaded?
    (state & STATE_UPLOADED) != 0
  end

  def deployed! unset_flag = false
    unless unset_flag
      update_attribute(:state, (state | STATE_DEPLOYED))
    else
      update_attribute(:state, (state ^ STATE_DEPLOYED)) if deployed?
    end
  end

  def deployed?
    (state & STATE_DEPLOYED) != 0
  end

  def to_s
    "#{schema} - #{schema_revision}"
  end

  def add_to_version_control(vc_username, vc_password)
    begin 
      asvc = init_asvc(vc_password, vc_username)
      
      version_update_sql, version_rollback_sql, version_preparation_txt = version_sql_working_copy_paths(asvc.vc_working_copy, schema)
      
      version_update_sql.print!(SqlController.new.update_sql(self))
      version_rollback_sql.print!(SqlController.new.rollback_sql(self))
      
      files_to_add = [version_update_sql.path, version_rollback_sql.path]

      unless preparation.empty?
        version_preparation_txt.print!(preparation) 
        files_to_add << version_preparation_txt.path
      end
  
      if initial_version?
        files_to_add = rio(asvc.vc_working_copy, schema).path
      end

      asvc.vc.add(files_to_add)
      asvc.vc.commit(asvc.vc_working_copy.path, "TOOL Add version #{schema_version} SQL for #{activity.app.name}, schema #{schema}")
      
      uploaded!
    rescue
      uploaded! true
      raise
    end
  end

  def delete_from_version_control(vc_username, vc_password)
    
    begin 
      asvc = init_asvc(vc_password, vc_username)
  
      version_update_sql, version_rollback_sql, version_preparation_txt = version_sql_working_copy_paths(asvc.vc_working_copy, schema)
      files_to_delete = [version_update_sql.path, version_rollback_sql.path]
      files_to_delete << version_preparation_txt.path if File.exists? version_preparation_txt.path
  
      if initial_version?
        files_to_delete = rio(asvc.vc_working_copy, schema).path
      end
  
      asvc.vc.delete files_to_delete
      asvc.vc.commit(asvc.vc_working_copy.path, "TOOL Delete version #{schema_version} SQL for #{activity.app.name} schema #{schema}")
      
      uploaded! true
    rescue
      raise  
    end
  end

  private

  def init_asvc(vc_password, vc_username)
    if activity.app.vc_path.blank?
      raise Brazil::VersionControlException, "the application must have an Version Control Path set"
    end
    
    Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => activity.app.vc_path, :vc_user => vc_username, :vc_password => vc_password, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
  end

  def version_sql_working_copy_paths(version_working_copy, db_schema)
    version_sql_dir = rio(version_working_copy, schema, activity.db_type.downcase)
    version_sql_dir.mkpath
    [rio(version_sql_dir, "#{db_schema}-#{schema_version}-update.sql").mode("w+"), rio(version_sql_dir, "#{db_schema}-#{schema_version}-rollback.sql").mode("w+"), rio(version_sql_dir, "#{db_schema}-#{schema_version}-preparation.txt").mode("w+")]
  end

  def check_no_duplicate_schema_db
    #TODO
    match = DbInstanceVersion.find(:first, :joins => [:version, :db_instance], :conditions => ['versions.schema = ? AND db_instances.id = ? AND versions.activity_id = ?', schema, db_instance_test.id, activity.id])
    if match && match.version_id != id
      errors.add(:base, "Creating a second Version with the same Schema '#{schema}' and Test Database '#{db_instance_test}' is not allowed")
      false
    end
  end

  def update_activity_state
    if activity.development?
      activity.versioned!
    end
  end

  def check_version_destroy_state
    unless created?
      errors.add(:base, "You can only delete versions in state '#{Version::STATE_CREATED}', this version is in state '#{state}'.")
      false
    end
  end
end

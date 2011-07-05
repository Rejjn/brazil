
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
    
    if next_schema_version
      self.schema_version = next_schema_version.to_s
      self.create_schema_version = false
    else
      self.schema_version = '1_0_0'
      self.create_schema_version = true
    end
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

  private
  
  # test = :update or :rollback
  def update_test_state(test, success = true)
    if created?
      if success
        return {:update => STATE_UPDATE_TESTED, :rollback => STATE_ROLLBACK_TESTED}.fetch(test)
      else
        return STATE_CREATED
      end
    elsif update_tested?
      if success
        return ""
      else
        return ""
      end
    elsif rollback_tested?
      if success
        return ""
      else
        return ""
      end      
    end
    
    return STATE_CREATED
  end

  def add_version_sql_to_version_control(update_sql, rollback_sql, db_schema, vc_username, vc_password)
    vc_tools = init_vc(vc_password, vc_username)
    
    version_update_sql, version_rollback_sql = version_sql_working_copy_paths(vc_tools.vc_working_copy, db_schema)
    version_update_sql.print!(update_sql)
    version_rollback_sql.print!(rollback_sql)

    logger.info "WC PATH :" << vc_tools.vc_working_copy.path

    vc_tools.vc.add(rio(vc_tools.vc_working_copy, activity.schema).path)
    vc_tools.vc.commit(vc_tools.vc_working_copy.path, "TOOL Add version #{schema_version} SQL for #{activity.app.name} schema #{schema}")
  end

  def delete_version_sql_from_version_control(db_schema, vc_username, vc_password)
    vc_tools = init_vc(vc_password, vc_username)

    version_update_sql, version_rollback_sql = version_sql_working_copy_paths(vc_tools.vc_working_copy, db_schema)
    vc_tools.vc.delete(version_update_sql.path)
    vc_tools.vc.delete(version_rollback_sql.path)

    vc_tools.vc.commit([version_update_sql.path, version_rollback_sql.path], "TOOL Delete version #{schema_version} SQL for #{activity.app.name} schema #{schema}")
  end

  def init_vc(vc_password, vc_username)
    if activity.app.vc_path.blank?
      raise Brazil::VersionControlException, "the application must have an Version Control Path set"
    end
    
    Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => activity.app.vc_path, :vc_user => vc_username, :vc_password => vc_password, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
  end

  def version_sql_working_copy_paths(version_working_copy, db_schema)
    version_sql_dir = rio(version_working_copy, activity.schema, activity.db_type.downcase).mkpath
    [rio(version_sql_dir, "#{db_schema}-#{schema_version}-update.sql").mode("w+"), rio(version_sql_dir, "#{db_schema}-#{schema_version}-rollback.sql").mode("w+")]
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

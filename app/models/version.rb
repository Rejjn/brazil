require 'rio'

require 'brazil/schema_revision'
require 'brazil/schema_version_control'
require 'brazil/version_control'

class Version < ActiveRecord::Base
  STATE_CREATED = 'created'
  STATE_TESTED = 'tested'
  STATE_DEPLOYED = 'deployed'
  STATE_MERGED = 'merged'

  belongs_to :activity

  has_many :db_instance_version
  has_many :db_instances, :through => :db_instance_version

  validates_presence_of :update_sql, :rollback_sql, :schema_version
  validates_inclusion_of :create_schema_version, :in => [true, false]

  #before_save :check_no_duplicate_schema_db,
  before_save :update_activity_state
  before_destroy :check_version_destroy_state

  def deploy_to_test(versioned_update_sql, versioned_rollback_sql, db_schema, test_db_instance, test_db_schema, test_db_username, test_db_password, vc_username, vc_password)
    db_tools = init_db(test_db_instance.host, test_db_instance.port, test_db_instance.db_type, test_db_schema, test_db_username, test_db_password)
    db_update_sql = db_tools.prepare_sql(test_db_instance.db_type, versioned_update_sql, test_db_schema, test_db_schema, test_db_schema)
    db_tools.execute_sql(db_update_sql)

    add_version_sql_to_version_control(versioned_update_sql, versioned_rollback_sql, db_schema, vc_username, vc_password)
    
    return db_update_sql
  rescue Brazil::DBException => db_exception
    errors.add_to_base("SQL: #{db_exception}")
    return db_exception.data
  rescue Brazil::VersionControlException => vc_exception
    errors.add_to_base("Version Control: could not add Version update and rollback SQL (#{vc_exception})")
  end

  def rollback_from_test(versioned_rollback_sql, db_schema, test_db_instance, test_db_schema, test_db_username, test_db_password, vc_username, vc_password)
    db_tools = init_db(test_db_instance.host, test_db_instance.port, test_db_instance.db_type, test_db_schema, test_db_username, test_db_password)
    db_rollback_sql = db_tools.prepare_sql(test_db_instance.db_type, versioned_rollback_sql, test_db_schema, test_db_schema, test_db_schema)
    db_tools.execute_sql(db_rollback_sql)
    
    delete_version_sql_from_version_control(db_schema, vc_username, vc_password)

    return db_rollback_sql
  rescue Brazil::DBException => db_exception
    errors.add_to_base("SQL: #{db_exception}")
    return db_exception.data
  rescue Brazil::VersionControlException => vc_exception
    errors.add_to_base("Version Control: could not delete Version update and rollback SQL (#{vc_exception})")
  end


  def init_schema_version
    begin
      vc_tools = Brazil::VersionControlTools.new
      vc_tools.configure(Brazil::VersionControlTools::TYPE_SVN, ::AppConfig.vc_uri, activity.vc_path, ::AppConfig.vc_read_user, ::AppConfig.vc_read_password, ::AppConfig.vc_dir)

      next_schema_version = vc_tools.find_next_schema_version
    rescue => exception
      unless exception.to_s =~ /reason_phrase=\"Not Found\"/ 
        errors.add_to_base("Could not lookup version for schema '#{schema}' (#{exception})")
        return
      end
    end
    
    if next_schema_version
      self.schema_version = next_schema_version
      self.create_schema_version = false
    else
      self.schema_version = '1_0_0'
      self.create_schema_version = true
    end
  end


  def update_schema_version(updated_schema_version, db_username, db_password)
    begin
      vc_tools = Brazil::VersionControlTools.new
      vc_tools.configure(Brazil::VersionControlTools::TYPE_SVN, ::AppConfig.vc_uri, activity.vc_path, ::AppConfig.vc_read_user, ::AppConfig.vc_read_password, ::AppConfig.vc_dir)
      
      next_schema_version = vc_tools.find_next_schema_version
    rescue => exception
      unless exception.to_s =~ /reason_phrase=\"Not Found\"/ 
        errors.add_to_base("Could not lookup version for schema '#{schema}' (#{exception})")
        return
      end
    end


    next_schema_revision = Brazil::SchemaRevision.from_string(next_schema_version)
    if next_schema_version
      self.create_schema_version = false
    else
      self.create_schema_version = true
      next_schema_revision = Brazil::SchemaRevision.new(1, 0, 0)
    end

    updated_schema_revision = Brazil::SchemaRevision.from_string(updated_schema_version)
    if updated_schema_revision && updated_schema_revision >= next_schema_revision
      self.schema_version = updated_schema_version
    else
      errors.add_to_base("Updated schema version: #{updated_schema_revision}, can not be less than the next schema version: #{next_schema_revision}")
    end
  end

  def merge_to_dev(update_sql, dev_db_instance_id, dev_schema, db_username, db_password)
    DbInstance.find(dev_db_instance_id).execute_sql(update_sql, db_username, db_password, dev_schema)
  rescue ActiveRecord::RecordNotFound
    errors.add_to_base("Can not find db instance with id: #{dev_db_instance_id}")
  rescue Brazil::DBException => db_exception
    errors.add_to_base("SQL: #{db_exception}")
  end

  def schema_revision
    Brazil::SchemaRevision.from_string(schema_version)
  end

  def created?
    (state == STATE_CREATED)
  end

  def tested?
    (state == STATE_TESTED)
  end

  def deployed?
    (state == STATE_DEPLOYED)
  end

  def to_s
    "#{schema} - #{schema_revision}"
  end

  private

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
    
    vc_tools = Brazil::VersionControlTools.new
    vc_tools.configure(Brazil::VersionControlTools::TYPE_SVN, ::AppConfig.vc_uri, activity.app.vc_path, vc_username, vc_password, ::AppConfig.vc_dir)
    vc_tools.init_vc
    
    vc_tools
  end
  
  
  def init_db(host, port, db_type, db_schema, db_username, db_password)
    db_tools = Brazil::DatabaseTools.new
    db_tools.configure(host, port, db_type, db_schema, db_username, db_password)
    
    db_tools
  end

=begin
  def init_vc(vc_password, vc_username)
    version_repos_path = "#{::AppConfig.vc_uri}#{activity.app.vc_path}"
    vc = Brazil::VersionControl.new(::AppConfig.vc_type, version_repos_path, vc_username, vc_password)
    unless vc.valid_credentials?
      raise Brazil::VersionControlException, "version control username or password are not correct"
    end
    return vc
  end
=end

  def version_sql_working_copy_paths(version_working_copy, db_schema)
    version_sql_dir = rio(version_working_copy, activity.schema, activity.db_type.downcase).mkpath
    [rio(version_sql_dir, "#{db_schema}-#{schema_version}-update.sql").mode("w+"), rio(version_sql_dir, "#{db_schema}-#{schema_version}-rollback.sql").mode("w+")]
  end

  def check_no_duplicate_schema_db
    #TODO
    match = DbInstanceVersion.find(:first, :joins => [:version, :db_instance], :conditions => ['versions.schema = ? AND db_instances.id = ? AND versions.activity_id = ?', schema, db_instance_test.id, activity.id])
    if match && match.version_id != id
      errors.add_to_base("Creating a second Version with the same Schema '#{schema}' and Test Database '#{db_instance_test}' is not allowed")
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
      errors.add_to_base("You can only delete versions in state '#{Version::STATE_CREATED}', this version is in state '#{state}'.")
      false
    end
  end
end

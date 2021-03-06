
class DbInstance < ActiveRecord::Base
  ENV_DEV = 'dev'
  ENV_TEST = 'test'
  ENV_PROD = 'prod'

  TYPE_MYSQL = Brazil::DatabaseSchema::TYPE_MYSQL
  TYPE_ODBC = Brazil::DatabaseSchema::TYPE_ODBC
  TYPE_ORACLE = Brazil::DatabaseSchema::TYPE_ORACLE
  TYPE_POSTGRES = Brazil::DatabaseSchema::TYPE_POSTGRES

  validates_presence_of :db_alias, :host, :port, :db_env, :db_type

  scope :env_test, :conditions => {:db_env => ENV_TEST}, :order => 'db_alias ASC' 
  scope :env_dev, :conditions => {:db_env => ENV_DEV}, :order => 'db_alias ASC'

  def self.by_db_type db_type 
    where(:db_type => db_type).order('db_alias ASC')
  end

  def self.db_environments
    [ENV_DEV, ENV_TEST, ENV_PROD]
  end

  def self.db_types
    # TODO: Only MySQL, Oracle and PostgreSQL support implemented for now
    [TYPE_MYSQL, TYPE_ORACLE, TYPE_POSTGRES] #, TYPE_ODBC ]
  end

  def dev?
    (db_env == DbInstance::ENV_DEV)
  end

  def test?
    (db_env == DbInstance::ENV_TEST)
  end

  def wipeable_schemas?
    (wipeable_schemas || db_type == TYPE_MYSQL)
  end

  def to_s
    db_alias
  end

  def deploy_update(app, app_schema, username, password, schema, target_version) 
    db = Brazil::DatabaseSchema.new(host, port, db_type, schema, username, password)
    asvc = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => app.vc_path, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
    
    db.update_to_version(asvc, app_schema, target_version)
  end

  def deploy_rollback(app, app_schema, username, password, schema, target_version)
    db = Brazil::DatabaseSchema.new(host, port, db_type, schema, username, password)
    asvc = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => app.vc_path, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
    
    db.rollback_to_version(asvc, app_schema, target_version)
  end

  def suggest_rollback_sql update_sql
    db = Brazil::DatabaseSchema.new(host, port, db_type, 'schema', 'username', 'password')
    db.suggest_rollback_sql(update_sql)
  end

  def execute_sql(sql, username, password, schema)
    sql = [{:sql => sql.to_s}] unless sql.class == Array
    db = Brazil::DatabaseSchema.new(host, port, db_type, schema, username, password)
    db.execute_sql_scripts(sql)
  end

  def deployed_versions(username, password, schema) 
    db = Brazil::DatabaseSchema.new(host, port, db_type, schema, username, password)
    db.version_information    
  end

  def wipe_schema(username, password, schema) 
    if wipeable_schemas? && db_type == TYPE_ORACLE
      serenity_api = Brazil::SerenityIntegration.new
      serenity_api.wipe_schema(db_type, :schema => schema, :port => port)
    elsif db_type == TYPE_MYSQL
      db = Brazil::DatabaseSchema.new(host, port, db_type, schema, username, password)
      db.execute_sql("DROP DATABASE `#{schema}`")
    end
  end

  def check_db_credentials(username, password, schema)
    db = Brazil::DatabaseSchema.new(host, port, db_type, schema, username, password)
    return db.check_db_credentials
  end

  private
  
end

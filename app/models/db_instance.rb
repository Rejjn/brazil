require 'brazil/schema_revision'
require 'brazil/database_tools'

class DbInstance < ActiveRecord::Base
  ENV_DEV = 'dev'
  ENV_TEST = 'test'
  ENV_PROD = 'prod'

  TYPE_MYSQL = Brazil::DatabaseTools::TYPE_MYSQL
  TYPE_ODBC = Brazil::DatabaseTools::TYPE_ODBC
  TYPE_ORACLE = Brazil::DatabaseTools::TYPE_ORACLE
  TYPE_POSTGRES = Brazil::DatabaseTools::TYPE_POSTGRES

  validates_presence_of :db_alias, :host, :port, :db_env, :db_type

  named_scope :env_test, :conditions => {:db_env => ENV_TEST}
  named_scope :env_dev, :conditions => {:db_env => ENV_DEV}

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

  def to_s
    db_alias
  end

  def execute_sql(sql, username, password, schema)
    db_tools = Brazil::DatabaseTools.new
    db_tools.configure(host, port, db_type, schema, username, password)

    db_tools.execute_sql(sql)
  end

  # kind can be either :current or :next
  def find_currently_deployed_schema_version(username, password, schema)
    db_tools = Brazil::DatabaseTools.new
    db_tools.configure(host, port, db_type, schema, username, password)

    db_tools.find_currently_deployed_schema_version
  end

  def check_db_credentials(username, password, schema)
    db_tools = Brazil::DatabaseTools.new
    db_tools.configure(host, port, db_type, schema, username, password)

    return db_tools.check_db_credentials
  end

  private
end

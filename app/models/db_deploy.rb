
require 'rio'
require 'httpclient'
require 'cobravsmongoose'

require 'brazil/schema_revision'
require 'brazil/version_control'
require 'brazil/database_tools'

class DbDeploy < ActiveRecord::Base
  
  SRC_TYPE_SVN = Brazil::DeploySourceTools::TYPE_SVN
  SRC_TYPE_BAMBOO = Brazil::DeploySourceTools::TYPE_BAMBOO
  
  belongs_to :db_instance
  
  validates_associated :db_instance
  validates_presence_of :db_schema, :db_user, :db_password, :src_type, :src_path
  
  def self.source_types
    [SRC_TYPE_SVN]
  end
  
  def find_available_versions current_version
    deploy_tools = Brazil::DeploySourceTools.new
    deploy_tools.configure(src_type, ::AppConfig.vc_uri, src_path, ::AppConfig.vc_read_user, ::AppConfig.vc_read_password, ::AppConfig.vc_dir)
    available_versions = deploy_tools.find_versions
    
    cv = Brazil::SchemaRevision::from_string(current_version)
    update_versions = available_versions.collect {|v| v if v > cv}.compact
    rollback_versions = available_versions.collect {|v| v if v < cv}.compact
    
    return update_versions, rollback_versions
  end
  
  def update_to_version target_version
    db_tools = Brazil::DatabaseTools.new
    db_tools.configure(db_instance.host, db_instance.port, db_instance.db_type, db_schema, db_user, db_password)
    db_tools.source_tools.configure(src_type, ::AppConfig.vc_uri, src_path, ::AppConfig.vc_read_user, ::AppConfig.vc_read_password, ::AppConfig.vc_dir)

    db_tools.update_to_version target_version
  end
  
  def rollback_to_version target_version
    db_tools = Brazil::DatabaseTools.new
    db_tools.configure(db_instance.host, db_instance.port, db_instance.db_type, db_schema, db_user, db_password)
    db_tools.source_tools.configure(src_type, ::AppConfig.vc_uri, src_path, ::AppConfig.vc_read_user, ::AppConfig.vc_read_password, ::AppConfig.vc_dir)

    db_tools.rollback_to_version target_version
  end
  
  def to_s
    "#{db_instance.to_s}/#{db_schema}"
  end

end

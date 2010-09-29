
require 'rio'
require 'httpclient'
require 'cobravsmongoose'

require 'brazil/schema_revision'
require 'brazil/version_control'

class DbDeploy < ActiveRecord::Base
  
  SRC_TYPE_SVN = 'svn'
  SRC_TYPE_BAMBOO = 'bamboo'
  
  belongs_to :db_instance
  
  def self.source_types
    [SRC_TYPE_SVN]
  end
  
  def find_available_versions current_version
    init_src
    
    cv = Brazil::SchemaRevision::from_string(current_version)
    available_versions = find_versions
    available_versions.sort!
    update_versions = available_versions.collect {|v| v if v > cv}.compact
    rollback_versions = available_versions.collect {|v| v if v < cv}.compact
    
    return update_versions, rollback_versions
  end
  
  def update_to_version target_version
    deploy_to_version(target_version, :update)
  end
  
  def rollback_to_version target_version
    if target_version == "0_0_0"
      begin
        clnt = HTTPClient.new
        response = clnt.put("#{::AppConfig.serenity_url}#{::AppConfig.serenity_clean_action}/#{db_instance.to_s}.xml")
        doc = CobraVsMongoose.xml_to_hash(response.content)
        return true, []
      rescue
        return false, []
      end
    else
      deploy_to_version(target_version, :rollback)
    end
  end
  
  # direction should be either :update or :rollback
  def deploy_to_version(target_version, direction) 
    init_src
    
    #todo
    current_version = db_instance.find_schema_version(db_instance.to_s, db_instance.to_s, db_instance.to_s, :current)
    
    sql = get_sql_for_deploy(current_version, target_version, direction)
    sql = prepare_sql(sql, db_instance.to_s, db_instance.to_s, db_instance.to_s)

    sql_results = []
    sql_failed = false
    sql.each do |sql_script|
      result = { 'sql_script' => sql_script, 'msg' => "Successfully executed", 'success' => true, 'run' => false }
      begin
        unless sql_failed
          db_instance.execute_sql(sql_script['sql'].join("\n"), db_instance.to_s, db_instance.to_s, db_instance.to_s)
          result['run'] = true
        end
      rescue
        result['msg'] = $!.to_s
        result['success'] = false
        
        sql_failed = true
      end
      
      sql_results << result
    end
    
    return !sql_failed, sql_results
  end
  
  def to_s
    db_instance.to_s
  end
  
  private 
  
  def set_version_working_copy working_copy
    @version_working_copy = working_copy
  end
  
  def version_working_copy
    raise StandardError, "version_working_copy not initialized, run init_src first!" if @version_working_copy == nil
    @version_working_copy
  end
  
  def find_versions
    update_files = version_working_copy.files['*-update.sql']
    
    versions = []
    update_files.each do |file|
      versions << Brazil::SchemaRevision::from_string(file.to_s.match(/-(\w+_\w+_\w+)-/)[1])
    end
    
    versions
  end
  
  def get_sql_for_deploy(current_version, target_version, direction)
    current_version = Brazil::SchemaRevision::from_string(current_version)
    target_version = Brazil::SchemaRevision::from_string(target_version)
    deploy_files = @version_working_copy.files["*-#{direction.to_s}.sql"]
    
    deploy_files.sort! do |x,y|
      x_version = Brazil::SchemaRevision::from_string(x.to_s.match(/-(\w+_\w+_\w+)-/)[1])
      y_version = Brazil::SchemaRevision::from_string(y.to_s.match(/-(\w+_\w+_\w+)-/)[1])
      x_version <=> y_version
    end
    
    #logger.info "deploy files: " << deploy_files.inspect
    #logger.info "current: #{current_version}, target: #{target_version}"
    
    selected_files = []
    deploy_files.each do |file|
      version = Brazil::SchemaRevision::from_string(file.to_s.match(/-(\w+_\w+_\w+)-/)[1])
      if direction == :update
        selected_files << file if current_version < version && version <= target_version
      else
        selected_files << file if current_version >= version && version > target_version
      end
    end
    selected_files.reverse! if direction == :rollback
    
    logger.info "selected files: " << selected_files.inspect
    
    sql = []
    selected_files.each do |file|
      sql_script = []
      file >> sql_script
      sql << {'file' => File.basename(file), 'sql' => sql_script}
    end
    
    logger.info "sql: " << sql.inspect
    
    sql
  end
  
  def prepare_sql(sql, schema_name, user_name, role_name)
    sql.each do |script|
      script['sql'].each do |line|
        #find all occurrences of schema name
        line.gsub!(/\s+\w+\.(\w+)/, " #{schema_name}.\\1")
        line.gsub!(/(TableSpace)\s("?)\w+("?)([\s,;])/i, "\\1 \\2#{schema_name}_INDEX\\3\\4")
        
        #find all occurrences of user name
        
        #find all occurrences of user role
        line.gsub!(/(To|From)\s+\w+_role([\s,;])/i, "\\1 #{schema_name}_ROLE\\2")
      end
    end
  end
  
  def init_src 
    if src_type == SRC_TYPE_SVN
      init_vc_src(::AppConfig.vc_read_user, ::AppConfig.vc_read_password)
    else
      init_bamboo_src
    end
  end
  
  def init_bamboo_src
    
  end
  
  def init_vc_src(vc_password, vc_username)
    logger.info
    
    version_repos_path = "#{::AppConfig.vc_uri}#{src_path}"
    vc = Brazil::VersionControl.new(::AppConfig.vc_type, version_repos_path, vc_username, vc_password)
    unless vc.valid_credentials?
      raise Brazil::VersionControlException, "version control username or password are not correct"
    end
    
    set_version_working_copy rio(::AppConfig.vc_dir, src_path)
    if version_working_copy.directory?
      vc.update(version_working_copy.path)
    else
      vc.checkout(version_working_copy.path)
    end    
  end  
end

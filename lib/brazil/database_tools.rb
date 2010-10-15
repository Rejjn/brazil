
require 'rio'
require 'httpclient'
require 'cobravsmongoose'

require 'brazil/schema_revision'
require 'brazil/version_control'
require 'brazil/deploy_source_tools'

module Brazil
  class DatabaseTools
  
    TYPE_MYSQL = 'MySQL'
    TYPE_ODBC = 'ODBC'
    TYPE_ORACLE = 'Oracle8'
    TYPE_POSTGRES = 'PostgreSQL'  
  
    attr_reader :source_tools
  
    def initialize()
      @source_tools = DeploySourceTools.new
    end
  
    def configure(db_host, db_port, db_type, db_schema, db_user, db_password)
      @db_host = db_host
      @db_port = db_port
      @db_type = db_type
      @db_schema = db_schema
      @db_user = db_user
      @db_password = db_password
      @db_configured = true
    end
  
    def update_to_version target_version
      #TODO
      #raise error if not configured
      
      deploy_to_version(target_version, :update)
    end
    
    def rollback_to_version target_version
      #TODO
      #raise error if not configured
      
      if target_version == "0_0_0"
        clean_serenity_db
      else
        deploy_to_version(target_version, :rollback)
      end
    end
    
    # direction should be either :update or :rollback
    def deploy_to_version(target_version, direction) 
      current_version = find_currently_deployed_schema_version
      
      sql = get_sql_for_deploy(current_version, target_version, direction)
  
      sql_results = []
      sql_failed = false
      sql.each do |sql_script|
        result = { :sql_script => sql_script, :msg => "Successfully executed", :success => true, :run => false }
        begin
          unless sql_failed
            execute_sql(prepare_sql(@db_type, sql_script[:sql], @db_schema, @db_schema, @db_schema))
            result[:run] = true
          end
        rescue
          result[:msg] = "#{$!.to_s} (#{$!})"
          result[:success] = false
          
          sql_failed = true
        end
        
        sql_results << result
      end
      
      return !sql_failed, sql_results
    end
  
    def execute_sql(sql, db_connection = nil)
      begin
        db_connection = create_db_connection unless db_connection
        db_connection['AutoCommit'] = false
        db_connection.transaction do |dbh|
          sql_no_comments = sql.gsub(/\-\-\s.*?[\n\r]/, '')
           sql_no_comments.strip.split(/;(?:[\n\r])?/s).each do |sql_part|
            dbh.do(super_strip(sql_part))
          end
        end
      rescue DBI::DatabaseError => exception
        new_exception = Brazil::DBExecuteSQLException.new exception.errstr
        new_exception.data = sql
        raise new_exception 
      ensure
        if db_connection
          db_connection['AutoCommit'] = true
          db_connection.disconnect
        end
      end
    end
    
    def super_strip str
      #str.gsub(/^\n+(.*?)$/, "\\1") #.gsub(/`/, "")
      str.strip
    end
    
    def clean_serenity_db
      clnt = HTTPClient.new
      response = nil
      case @db_type
        when TYPE_ORACLE then
          response = clnt.put("#{::AppConfig.serenity_url}#{::AppConfig.serenity_clean_action}/#{@db_schema}.xml")
        when TYPE_MYSQL then
          response = clnt.put("#{::AppConfig.serenity_url}#{::AppConfig.serenity_clean_action}/mysql:#{@db_port}.xml")
      end
      doc = CobraVsMongoose.xml_to_hash(response.content)
      
      if !(defined? doc['hash']) || !(doc['hash']['status']['$'] == 'success')
        raise RemoteAPIException, 'failed to clean database - ' << doc["hash"]["message"]['$']
      end
    end
  
    def find_currently_deployed_schema_version
      schema_version = nil
      db_connection = nil
  
      unless check_db_credentials
        raise Brazil::DBConnectionException, "Failed to verify connection paramaters, please check host/sid, port, schema"
      end
  
      begin
        db_connection = create_db_connection
        latest_version_row = db_connection.select_one("SELECT MAJOR,MINOR,PATCH FROM #{@db_schema}.schema_versions ORDER BY major DESC, minor DESC, patch DESC")
        if latest_version_row
          schema_version = Brazil::SchemaRevision.new(latest_version_row['MAJOR'], latest_version_row['MINOR'], latest_version_row['PATCH']).to_s
        end
      rescue DBI::DatabaseError => exception
        # No schema_versions table found, return no schema version
      ensure
        db_connection.disconnect if db_connection
      end
  
      if !schema_version
        schema_version = "N/A"
      end
  
      return schema_version
    end
  
    def check_db_credentials
      db_connection = nil
      begin
        db_connection = create_db_connection
      rescue DBI::DatabaseError => exception
        #raise DBConnectionException, "DB Credentials were not correct, #{@db_user}@#{@db_schema}"
        raise exception
        return false
      ensure
        db_connection.disconnect if db_connection
      end
  
      return true
    end
  
    def create_db_connection
      begin
        require 'dbi'
      rescue LoadError
        raise Brazil::LoadException, 'Failed to load the DBI module, please install.'
      end
  
      connection = nil
      case @db_type
      when TYPE_MYSQL
        begin
          retried = false
          connection = DBI.connect("DBI:Mysql:database=#{@db_schema};host=#{@db_host};port=#{@db_port}", @db_user, @db_password)
        rescue DBI::DatabaseError => exception
          if exception.to_s =~ /unknown database/i && !retried
            none_db_connection = DBI.connect("DBI:Mysql:host=#{@db_host};port=#{@db_port}", @db_user, @db_password)
            execute_sql("CREATE DATABASE #{@db_schema}", none_db_connection)
            retried = true
            retry
          end
        end
        connection.do('SET NAMES utf8') if connection
          
      # when TYPE_ODBC
      when TYPE_ORACLE
        oracle_host, oracle_instance = @db_host.split('/')
        connection = DBI.connect("DBI:OCI8://#{oracle_host}:#{@db_port}/#{oracle_instance}", @db_user, @db_password)
      when TYPE_POSTGRES
        connection = DBI.connect("DBI:Pg:database=#{@db_schema};host=#{@db_host};port=#{@db_port}", @db_user, @db_password)
      else
        raise Brazil::UnknownDBTypeException, "Trying to create connection for unsupported DB Type: #{@db_type}"
      end
  
      if connection.nil?
        raise Brazil::DBConnectionException, "Failed to connect to DB (#{@db_user}@#{@db_host}:#{@db_port}/#{@db_schema})"
      else
        return connection
      end
    end
    
    def get_sql_for_deploy(current_version, target_version, direction)
      src_working_copy = source_tools.init_src
      
      current_version = Brazil::SchemaRevision::from_string(current_version)
      target_version = Brazil::SchemaRevision::from_string(target_version)
      deploy_files = src_working_copy.files["*-#{direction.to_s}.sql"]
      
      deploy_files.sort! do |x,y|
        x_version = Brazil::SchemaRevision::from_string(x.to_s.match(/-(\w+_\w+_\w+)-/)[1])
        y_version = Brazil::SchemaRevision::from_string(y.to_s.match(/-(\w+_\w+_\w+)-/)[1])
        x_version <=> y_version
      end
      
      selected_files = []
      deploy_files.each do |file|
        version = Brazil::SchemaRevision::from_string(file.to_s.match(/-(\w+_\w+_\w+)-/)[1])
        if direction == :update
          selected_files << file if current_version < version && version <= target_version
        else
          selected_files << file if current_version >= version && version > target_version
        end
      end

      if selected_files.empty?
        raise InvalidTargetVersionException, "Target version resulted in an empty SQL set, check target version"
      end
      
      selected_files.reverse! if direction == :rollback
      
      sql = []
      selected_files.each do |file|
        sql_script = []
        file >> sql_script
        sql << {:file => File.basename(file), :sql => sql_script}
      end
      
      sql
    end
    
    def prepare_sql(db_type, sql, schema_name, user_name, role_name)
      
      if sql.is_a? String
        sql = sql.split("\n")
      end
      
      case db_type
        when TYPE_ORACLE then
          sql.each do |line|
            #find all occurrences of schema name
            line.gsub!(/\s+\w+\.(\w+)/, " #{schema_name}.\\1")
            line.gsub!(/(TableSpace)\s+("?)(\w+)_(DATA|INDEX|IDX)("?)/i, "\\1 \\2#{schema_name}_\\4\\5")
            
            #find all occurrences of user name
            
            #find all occurrences of user role
            line.gsub!(/(To|From)\s+\w+_role([\n\s,;])/i, "\\1 #{schema_name}_ROLE\\2")
          end
        when TYPE_MYSQL then
          
          sql.each do |line|
            line.gsub!(/CREATE DATABASE \w+;[\s\n\r]+/, "")
            line.gsub!(/USE \w+;[\s\n\r]+/, "")
            #line.gsub!(/\/\*\!.+;[\s\n\r]+/, "")
            
            line.gsub!(/\s+\w+\.(\w+)/i, " #{schema_name}.\\1")
          end
      end

      if sql.is_a? Array 
        sql = sql.join("\n")
      end
      
      sql 
    end
  end
end
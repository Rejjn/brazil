
require 'rio'

require 'brazil/schema_revision'
#require 'brazil/version_control_base'
require 'brazil/serenity_integration'

module Brazil
  class DatabaseSchema
  
    TYPE_MYSQL = 'mysql'
    TYPE_ODBC = 'odbc'
    TYPE_ORACLE = 'oracle8'
    TYPE_POSTGRES = 'postgresql'  
  
    def initialize(db_host, db_port, db_type, db_schema, db_user, db_password)
      @db_host = db_host
      @db_port = db_port
      @db_type = db_type
      @db_schema = db_schema
      @db_user = db_user
      @db_password = db_password
    end
  
    def update_to_version(app_schema_vc, app_schema, target_version)
      execute_sql_scripts sql_for_deploy(version_information, app_schema_vc, app_schema, target_version, :update)
    end
    
    def rollback_to_version(app_schema_vc, app_schema, target_version)
      execute_sql_scripts sql_for_deploy(version_information, app_schema_vc, app_schema, target_version, :rollback)
    end
  
    #
    # param sql format: 
    # sql << {:source => file_name/change/activity, :sql => sql_script}
    #
    def execute_sql_scripts sql_scripts
      
      begin 
        sql_scripts.each do |sql_script|
          tmp = sql_script[:source]
          tmp = sql_script[:sql]
        end
      rescue
        raise ArgumentException, 'SQL script hash has the wrong format!'
      end
      
      sql_results = []
      sql_failed = false
      sql_scripts.each do |sql_script|
        result = { :sql_script => sql_script, :msg => "Successfully executed", :success => true, :run => false }
        begin
          unless sql_failed
            sql = prepare_sql(@db_type, sql_script[:sql], @db_schema, @db_schema, @db_schema)
            result[:sql_script][:sql] = sql
            execute_sql(sql)
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
            dbh.do(sql_part.strip)
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
    
    def version_information
      schema_versions = []
      db_connection = nil
  
      unless check_db_credentials
        raise Brazil::DBConnectionException, "Failed to verify connection paramaters, please check host/sid, port, schema"
      end
  
      begin
        db_connection = create_db_connection
        case @db_type
          when TYPE_MYSQL
            version_rows = db_connection.select_all("SELECT major, minor, patch, created, description FROM #{@db_schema}.schema_versions ORDER BY major ASC, minor ASC, patch ASC")
            version_rows.each do |version|
              schema_versions << Brazil::SchemaRevision.new(version[0], version[1], version[2], version[3], version[4])
            end
          when TYPE_ORACLE 
            version_rows = db_connection.select_all("SELECT * FROM #{@db_schema}.schema_versions ORDER BY major ASC, minor ASC, patch ASC")
            version_rows.each do |version|
              schema_versions << Brazil::SchemaRevision.new(version['MAJOR'], version['MINOR'], version['PATCH'], version['CREATED'], version['DESCRIPTION'])
            end
        end
      rescue DBI::DatabaseError => exception
        # No schema_versions table found, return no schema version
      ensure
        db_connection.disconnect if db_connection
      end
      
      return schema_versions
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
  
    def suggest_rollback_sql update_sql
      rollback_sql = "-- ** IMPORTANT!! **\n-- THIS IS ONLY A SUGGESTION, YOU NEED TO EDIT IT TO ENSURE THAT IT WILL WORK PROPERLY !\n\n"
      
      case @db_type
        when TYPE_MYSQL
          sql_by_statement = update_sql.split(/;/)
    
          sql_by_statement.each do |sql_statement|
            found_match = false
            
            sql_statement.scan(/create (table|index|SEQUENCE|CONSTRAINT) ([`\w_\-\d]+\.[`\w_\-\d]+)/i) do |m|
              found_match = true
              rollback_sql << "DROP #{m[0]} #{m[1]};\n\n"
            end
            
            sql_statement.scan(/insert into ([`\w_\-\d]+\.[`\w_\-\d, ]+)\s*\((.+?)\) VALUES\s*\((.*)\)/i) do |m|
              keys = m[1].split(',')
              values = m[2].split(',')
              
              if keys.count == values.count 
                found_match = true
              
                where = ""
                keys.each do |key|
                  where << key + " = " + values.shift + ' AND '
                end
              
                rollback_sql << "DELETE FROM #{m[0]} WHERE #{where[0...-5]};\n\n"
              end
            end
            
            unless found_match
              rollback_sql << "-- ** ADD ROLLBACK FOR: **\n-- " + sql_statement.strip.gsub(/\n/, "\n-- ") + ";\n\n"
            end
          end

        when TYPE_ORACLE 
          sql_by_statement = update_sql.split(/;/)
    
          sql_by_statement.each do |sql_statement|
            found_match = false
            
            sql_statement.scan(/create (table|index|SEQUENCE|CONSTRAINT) ([\w_\-\d]+\.[\w_\-\d]+)/i) do |m|
              found_match = true
              rollback_sql << "DROP #{m[0]} #{m[1]};\n\n"
            end
            
            sql_statement.scan(/comment on (table|column) ([\w_\-\d]+\.[\w_\-\d]+)/i) do |m|
              found_match = true
              #we don't rollback comments...
            end
            
            sql_statement.scan(/grant ([SELECT|INSERT|UPDATE|DELETE|, ]+) ON ([\w_\-\d]+\.[\w_\-\d]+) TO ([\w_\-\d]+)/i) do |m|
              found_match = true
              rollback_sql << "REVOKE #{m[0]} ON #{m[1]} FROM #{m[2]};\n\n"
            end
            
#            sql_statement.scan(/insert into ([\w_\-\d]+\.[\w_\-\d, ]+)\s*\((.+?)\) VALUES\s*\((.*)\)/i) do |m|
#              keys = m[1].split(',')
#              values = m[2].split(',')
#              
#              if keys.count == values.count 
#                found_match = true
#              
#                where = ""
#                keys.each do |key|
#                  where << key + " = " + values.shift + ' AND '
#                end
#              
#                rollback_sql << "DELETE FROM #{m[0]} WHERE #{where[0...-5]};\n\n"
#              end
#            end
            
            unless found_match
              rollback_sql << "-- ** ADD ROLLBACK FOR: **\n-- " + sql_statement.strip.gsub(/\n/, "\n-- ") + ";\n\n"
            end
          end
      end
      
      rollback_sql
    end
  
    protected
  
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
    
    def sql_for_deploy(version_information, app_schema_vc, app_schema, target_version, direction)
      src_working_copy = app_schema_vc.vc_working_copy
      
      if version_information.count != 0
        current_version = version_information.last
      else
        current_version = Brazil::SchemaRevision.new(0, 0, 0)
      end
      
      target_version = Brazil::SchemaRevision::from_string(target_version)
      deploy_files = rio(src_working_copy.to_s, app_schema, @db_type).files["*-#{direction.to_s}.sql"]

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
          selected_files << file if current_version >= version && version >= target_version
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
        sql << {:source => File.basename(file.to_s), :sql => sql_script}
      end
      
      sql
    end

    
    def prepare_sql(db_type, sql, schema_name, user_name, role_name)
      
      if sql.is_a? String
        sql = sql.split("\n")
      end
      
      case db_type
        when TYPE_ORACLE then
          schema_regexp = '[\w\d\_\-]+'

          sql.each do |line|
            #find all occurrences of schema name
            line.gsub!(/\s+#{schema_regexp}\.(#{schema_regexp})/, " #{schema_name}.\\1")
            line.gsub!(/VALUES\s*\(\s*#{schema_regexp}\.(#{schema_regexp})/, "VALUES(#{schema_name}.\\1")
            line.gsub!(/(TableSpace)\s+("?)(#{schema_regexp})_(DATA|INDEX|IDX)("?)/i, "\\1 \\2#{schema_name}_\\4\\5")
            
            #find all occurrences of user name
            line.gsub!(/grant ([\w ,]+) on #{schema_regexp}.(\w+) to [\w\d\_\-]+;/i, "grant \\1 on #{schema_name}.\\2 to #{schema_name}_APP;")
            
            #find all occurrences of user role
            line.gsub!(/(To|From)\s+#{schema_regexp}_role([\n\s,;])/i, "\\1 #{schema_name}_ROLE\\2")
            
            # clean away comments, not allowed on last line by ODBC
            line.gsub!(/--.*?(\n|$)/, '')
          end
        when TYPE_MYSQL then
          schema_regexp = '[`\w\d\_\-]+'
          
          sql.each do |line|
            line.gsub!(/CREATE DATABASE \w+;[\s\n\r]+/, "")
            line.gsub!(/USE \w+;[\s\n\r]+/, "")
            #line.gsub!(/\/\*\!.+;[\s\n\r]+/, "")
            
            line.gsub!(/\s+[`\w\d_-]+\.(#{schema_regexp})/i, " #{schema_name}.\\1")
        end
      end

      if sql.is_a? Array 
        sql = sql.join("\n")
      end
      
      sql 
    end
  end
end

require 'uuidtools'
require 'rio'

module Brazil 
  class SessionSQLStorage
  
    def self.store_sql(sql)
      session_id = UUIDTools::UUID.timestamp_create.to_s
      rio("#{::AppConfig.sql_dir}").mkpath
      rio("#{::AppConfig.sql_dir}/#{session_id}") < sql
      session_id
    end
  
    def self.retrieve_sql(session_id)
      sql = ''
      rio("#{::AppConfig.sql_dir}/#{session_id}") > sql
      sql
    end
  end
end
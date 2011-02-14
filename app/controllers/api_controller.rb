
require 'brazil/database_tools'

class ApiController < ApplicationController

  layout false
  
  skip_filter :add_controller_crumbs

  def update
    respond_to do |format|
      begin
        raise RuntimeError, "parameter <host(/sid)> must be present" unless params[:host]
        raise RuntimeError, "parameter <port> must be present" unless params[:port]
        raise RuntimeError, "parameter <db_type> must be present" unless params[:db_type]
        raise RuntimeError, "parameter <db_schema> must be present" unless params[:db_schema]
        raise RuntimeError, "parameter <db_user> must be present" unless params[:db_user]
        raise RuntimeError, "parameter <db_password> must be present" unless params[:db_password]
        raise RuntimeError, "parameter <src_type> must be present" unless params[:src_type]
        raise RuntimeError, "parameter <src_uri> must be present" unless params[:src_uri]
        raise RuntimeError, "parameter <src_path> must be present" unless params[:src_path]
        raise RuntimeError, "parameter <target_version> must be present" unless params[:target_version]
        
        db_tools = Brazil::DatabaseTools.new
        db_tools.configure(params[:host], params[:port], params[:db_type], params[:db_schema], params[:db_user], params[:db_password])
        db_tools.source_tools.configure(params[:src_type], params[:src_uri], params[:src_path], ::AppConfig.vc_read_user, ::AppConfig.vc_read_password, ::AppConfig.vc_dir)
    
        success, sql_results = db_tools.update_to_version params[:target_version]
        
        #logger.info sql_results.inspect
        
        unless success
          failed_sql = nil
          sql_results.each do |sql|
            failed_sql = sql unless sql[:success]
          end
        
          raise RuntimeError, "Execution failed (#{failed_sql[:msg]}, sql:#{failed_sql[:sql_script]})"
        end
        
        format.xml  { render :xml => {:status => "success"}}
      rescue => exception
        format.xml  { render :xml => {:error => exception, :status => "error"}}
      end
    end
  end
  
  def rollback
    respond_to do |format|
      begin
        raise RuntimeError, "parameter <host> must be present" unless params[:host]
        raise RuntimeError, "parameter <port> must be present" unless params[:port]
        raise RuntimeError, "parameter <db_type> must be present" unless params[:db_type]
        raise RuntimeError, "parameter <db_schema> must be present" unless params[:db_schema]
        raise RuntimeError, "parameter <db_user> must be present" unless params[:db_user]
        raise RuntimeError, "parameter <db_password> must be present" unless params[:db_password]
        raise RuntimeError, "parameter <src_type> must be present" unless params[:src_type]
        raise RuntimeError, "parameter <src_uri> must be present" unless params[:src_uri]
        raise RuntimeError, "parameter <src_path> must be present" unless params[:src_path]
        raise RuntimeError, "parameter <target_version> must be present" unless params[:target_version]
        
        db_tools = Brazil::DatabaseTools.new
        db_tools.configure(params[:host], params[:port], params[:db_type], params[:db_schema], params[:db_user], params[:db_password])
        db_tools.source_tools.configure(params[:src_type], params[:src_uri], params[:src_path], ::AppConfig.vc_read_user, ::AppConfig.vc_read_password, ::AppConfig.vc_dir)
    
        success, sql_results = db_tools.rollback_to_version params[:target_version]
        
        #logger.info sql_results.inspect
        
        if !success && params[:target_version] != "0_0_0"
          failed_sql = nil
          sql_results.each do |sql|
            failed_sql = sql unless sql[:success]
          end
        
          raise RuntimeError, "Execution failed (#{failed_sql[:msg]}, sql:#{failed_sql[:sql_script]})"
        end
        
        format.xml  { render :xml => {:status => "success"}}
      rescue => exception
        format.xml  { render :xml => {:error => exception, :status => "error"}}
      end
    end
  end    
end

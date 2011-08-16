class DeployController < ApplicationController
  
  respond_to :html, :xml
  
  # GET /deploy
  # GET /deploy.xml
  def index
    @apps = App.all(:order => 'name ASC')

    respond_with
  end

  # GET /deploy/1
  # GET /deploy/1.xml
  def show_app
    respond_to do |format|
      begin
        @apps = App.all(:order => 'name ASC')
        @app = App.find(params[:app])
        
        set_app_schema_vc
        find_schemas
            
        format.html { render :action => "show_app" }
        format.xml
      rescue => exception
        flash[:error] = "Error while getting database schemas! #{exception} (#{exception.class})"
        format.html { render :action => "index" }
        format.xml  { render :status => :unprocessable_entity }
      end
    end
  end

  def show_schema
    respond_to do |format|
      begin
        @apps = App.all(:order => 'name ASC')
        @app = App.find(params[:app])
        
        set_app_schema_vc
        find_schemas
        
        find_selected_schema params[:schema]
        
        raise RuntimeError, "Schema #{params[:schema]} not found!" unless @schema
        find_db_instances @schema[:type]
            
        format.html { render :action => "show_schema" }
        format.xml
      rescue => exception
        flash[:error] = "Error while getting database instances! #{exception} (#{exception.class})"
        format.html { render :action => "show_app", :status => :unprocessable_entity }
        format.xml  { render :status => :unprocessable_entity }
      end
    end
  end

  def show_instance
    respond_to do |format|
      begin
        @apps = App.all(:order => 'name ASC')
        @app = App.find(params[:app])
        
        check_deploy_context params[:app], params[:schema], params[:db_instance]
        
        set_app_schema_vc
        find_schemas
        
        find_selected_schema params[:schema]
        
        raise RuntimeError, "Schema #{params[:schema]} not found!" unless @schema
        find_db_instances @schema[:type]
        
        @db_instance = DbInstance.find(params[:db_instance])
        set_credentials
        fetch_version_info
        
        format.html { render :action => "show_instance" }
        format.xml
      rescue => exception
        puts exception.backtrace  
        session.delete :db_credentials
        flash[:error] = "#{exception} (#{exception.class})"
        format.html { render :action => "show_instance", :status => :unprocessable_entity }
        format.xml  { render :status => :unprocessable_entity }
      end
    end
  end

  def wipe_credentials
    reset_credentials!
       
    show_instance
  end
  
  # PUT /deploy/1/deploy_update
  # PUT /deploy/1/deploy_update.xml
  def update
    respond_to do |format|
      if params[:target_version] && !params[:target_version].empty?
      
        begin 
          @app = App.find(params[:app])
          @db_instance = DbInstance.find(params[:db_instance])
          
          @run_successfull, @deployment_results = @db_instance.deploy_update(
                                                  @app,
                                                  params[:schema],
                                                  session[:db_credentials][:db_username], 
                                                  session[:db_credentials][:db_password],
                                                  session[:db_credentials][:target_schema],
                                                  params[:target_version])
          
          if @run_successfull
            flash[:notice] = "SQL successfully deployed to database"
          else
            flash[:error] = "Failed to deploy SQL to database (scripts may hasve been partially executed, see below)"
          end
          
          load_for_deploy_fieldset
          format.html { render :partial => 'deploy_fieldset' }
          format.xml
        rescue => e
          flash[:error] = "Failed to update database schema! (#{e})"
          load_for_deploy_fieldset

          format.html { render :partial => 'update_fieldset', :locals => {:update_versions => @update_versions}, :status => :unprocessable_entity }
          format.xml  { render :status => :unprocessable_entity }
        end    
      else
        flash[:error] = "Target version is not set"
        load_for_deploy_fieldset
        
        format.html { render :partial => 'update_fieldset', :locals => {:update_versions => @update_versions}, :status => :unprocessable_entity }
        format.xml  { render :status => :unprocessable_entity }      
      end
    end
  end
  
  # PUT /deploy/1/deploy_rollback
  # PUT /deploy/1/deploy_rollback.xml
  def rollback
    respond_to do |format|
      if params[:target_version] && !params[:target_version].empty?
        begin 
          @app = App.find(params[:app])
          @db_instance = DbInstance.find(params[:db_instance])
          
          @run_successfull, @deployment_results = @db_instance.deploy_rollback(
                                                  @app,
                                                  params[:schema],
                                                  session[:db_credentials][:db_username], 
                                                  session[:db_credentials][:db_password],
                                                  session[:db_credentials][:target_schema],
                                                  params[:target_version])
          
          load_for_deploy_fieldset
          format.html { render :partial => 'deploy_fieldset' }
          format.xml
        rescue => e
          flash[:error] = "Failed to wipe database schema! (#{e})"
          
          load_for_deploy_fieldset
          format.html { render :partial => 'rollback_fieldset', :locals => {:rollback_versions => @rollback_versions }, :status => :unprocessable_entity }
          format.xml  { render :status => :unprocessable_entity }
        end    
      else
        flash[:error] = "Target version is not set"
        load_for_deploy_fieldset
        format.html { render :partial => 'rollback_fieldset', :locals => {:rollback_versions => @rollback_versions }, :status => :unprocessable_entity }
        format.xml  { render :status => :unprocessable_entity }      
      end
    end  
  end
  
  # PUT /deploy/1/deploy_rollback
  # PUT /deploy/1/deploy_rollback.xml
  def wipe
    respond_to do |format|
      begin 
        @db_instance = DbInstance.find(params[:db_instance])
        @db_instance.wipe_schema(session[:db_credentials][:db_username], session[:db_credentials][:db_password], session[:db_credentials][:target_schema])
        
        flash[:notice] = "Schema wiped!"
        
        load_for_deploy_fieldset
        format.html { render :partial => 'deploy_fieldset' }
        format.xml
      rescue => e
        flash[:error] = "Failed to wipe database schema! (#{e})"
        
        load_for_deploy_fieldset
        format.html { render :partial => 'wipe_fieldset', :status => :unprocessable_entity }
        #format.html { render :partial => 'deploy_fieldset', :status => :unprocessable_entity }
        format.xml  { render :status => :unprocessable_entity }
      end    
    end    
  end
  
  private
  
  def load_for_deploy_fieldset
    @app = App.find(params[:app])
    
    set_app_schema_vc
    find_schemas
    find_selected_schema params[:schema]
    find_db_instances @schema[:type]
    @db_instance = DbInstance.find(params[:db_instance])
    fetch_version_info    
  end
  
  def add_controller_crumbs
    add_crumb 'Deploy Database', deploy_path
  end  

  def set_app_schema_vc
    @vscm = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @app.vc_path, :vc_uri => ::AppConfig.vc_uri)
  end

  def find_schemas
    begin
      @schemas = []
      @vc_schemas = []
      
      @vc_schemas = @vscm.find_schemas
      @brazil_schemas = []
      @app.activities.each do |activity|
        @brazil_schemas << activity.schema
      end
      @schemas = (@vc_schemas + @brazil_schemas).uniq.sort
    #rescue => e
    #  raise RuntimeError, "mamma"      
    end
  end      

  def find_selected_schema schema
    source, type = ''
    if @vc_schemas.include? schema
      source = 'subversion'
      type = @vscm.find_schema_type schema
    else
      source = 'brazil'
      activity = @app.activities.where(:schema => schema).limit(1).first
      type = activity.db_type 
    end
      
    @schema = {:name => schema, :source => source, :type => type}
  end
  
  def find_db_instances type
    @db_instances = DbInstance.where(:db_type => type, :db_env => [DbInstance::ENV_DEV, DbInstance::ENV_TEST]).order('db_alias ASC')
    @db_instances_grouped = { DbInstance::ENV_DEV => [], DbInstance::ENV_TEST => [] }
    @db_instances.each do |db|
      @db_instances_grouped[db.db_env] << [db.db_alias, db.id]
    end
  end
  
  def check_deploy_context app, schema, instance
    same = true
    
    if session[:deploy_target] && session[:deploy_target][:app] && session[:deploy_target][:schema] && session[:deploy_target][:instance]
      if session[:deploy_target][:app] != app || session[:deploy_target][:schema] != schema || session[:deploy_target][:instance] != instance
        reset_credentials!  
      end
    end
    
    session[:deploy_target] = {:app => app, :schema => schema, :instance => instance }
    
    same
  end
  
  def reset_credentials!
    session.delete :db_credentials
  end
  
  def set_credentials
    if params[:db_username] && params[:db_password]
        session[:db_credentials] = {:db_username => params[:db_username].dup, :db_password => params[:db_password].dup, :target_schema => params[:target_schema].dup}
    end
  end

  def fetch_version_info
    @update_versions = []
    @rollback_versions = []
    @version_info = []
    
    @version_info = @db_instance.deployed_versions(session[:db_credentials][:db_username], session[:db_credentials][:db_password], session[:db_credentials][:target_schema]) if session[:db_credentials]
    
    @vscm.find_versions(@schema[:name]).each do |version|
      if version > @version_info.last
        @update_versions << version
      else
        @rollback_versions << version
      end
    end
  end
end


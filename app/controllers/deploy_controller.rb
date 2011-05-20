class DeployController < ApplicationController
  # GET /deploy
  # GET /deploy.xml
  def index
    @apps = App.all

    puts @apps.inspect

    respond_to do |format|
      format.html # index.html.erb
      format.xml 
    end
  end

  # GET /deploy/1
  # GET /deploy/1.xml
  def show_app
    respond_to do |format|
      begin
        @apps = App.all
        @app = App.find(params[:app])
        
        set_app_schema_vc
        find_schemas
            
        format.html { render :action => "show_app" }
        format.xml
      rescue => exception
        compile_grouped_dbi_list
        flash[:error] = "#{exception} (#{exception.class})"
        format.html { render :action => "show_app" }
        format.xml  { render :status => :unprocessable_entity }
      end
    end
  end

  def show_schema
    respond_to do |format|
      begin
        @apps = App.all
        @app = App.find(params[:app])
        
        set_app_schema_vc
        find_schemas
        
        find_selected_schema params[:schema]
        find_db_instances @schema[:type]
            
        format.html { render :action => "show_schema" }
        format.xml
      rescue => exception
        compile_grouped_dbi_list
        flash[:error] = "#{exception} (#{exception.class})"
        format.html { render :action => "show_schema" }
        format.xml  { render :status => :unprocessable_entity }
      end
    end
  end

  def show_instance
    respond_to do |format|
      begin
        @apps = App.all
        @app = App.find(params[:app])
        
        set_app_schema_vc
        find_schemas
        
        find_selected_schema params[:schema]
        find_db_instances @schema[:type]
            
        @db_instance = DbInstance.find(params[:db_instance])
        set_credentials
        fetch_version_info
            
        format.html { render :action => "show_instance" }
        format.xml
      rescue => exception
        compile_grouped_dbi_list
        flash[:error] = "#{exception} (#{exception.class})"
        format.html { render :action => "show_instance" }
        format.xml  { render :status => :unprocessable_entity }
      end
    end
  end

  def wipe_credentials
    session.delete :db_credentials
    
    show_instance
  end
  
  # PUT /deploy/1/deploy_update
  # PUT /deploy/1/deploy_update.xml
  def update
    if params[:target_version] && !params[:target_version].empty?
      respond_to do |format|
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
          
          load_for_deoploy_fieldset
          format.html { render :partial => 'deploy_fieldset' }
          format.xml
        rescue => e
          flash[:error] = "Failed to wipe database schema! (#{e})"
          
          load_for_deoploy_fieldset
          format.html { render :partial => 'deploy_fieldset' }
          format.xml  { render :status => :unprocessable_entity }
        end    
      end  
    else
      flash[:error] = "Target version is not set"
      load_for_deoploy_fieldset
      format.html { render :partial => 'deploy_fieldset' }
      format.xml  { render :status => :unprocessable_entity }      
    end
  end
  
  # PUT /deploy/1/deploy_rollback
  # PUT /deploy/1/deploy_rollback.xml
  def rollback
    if params[:target_version] && !params[:target_version].empty?
      respond_to do |format|
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
          
          load_for_deoploy_fieldset
          format.html { render :partial => 'deploy_fieldset' }
          format.xml
        rescue => e
          flash[:error] = "Failed to wipe database schema! (#{e})"
          
          load_for_deoploy_fieldset
          format.html { render :partial => 'deploy_fieldset' }
          format.xml  { render :status => :unprocessable_entity }
        end    
      end  
    else
      flash[:error] = "Target version is not set"
      load_for_deoploy_fieldset
      format.html { render :partial => 'deploy_fieldset' }
      format.xml  { render :status => :unprocessable_entity }      
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
        
        load_for_deoploy_fieldset
        format.html { render :partial => 'deploy_fieldset' }
        format.xml
      rescue => e
        flash[:error] = "Failed to wipe database schema! (#{e})"
        
        load_for_deoploy_fieldset
        format.html { render :partial => 'deploy_fieldset' }
        format.xml  { render :status => :unprocessable_entity }
      end    
    end    
  end
  
  private
  
  def load_for_deoploy_fieldset
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

  def compile_grouped_dbi_list
    @grouped_db_instances = {}
    DbInstance.db_environments.each do |env|
      @grouped_db_instances[env] = []  
    end
    
    all_db_instances = DbInstance.all
    all_db_instances.each do |db|
      @grouped_db_instances[db.db_env] << [db.db_alias, db.id]
    end
  end

  def set_app_schema_vc
    @vscm = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @app.vc_path, :vc_uri => ::AppConfig.vc_uri)
  end

  def find_schemas
    @schemas = []
    @vc_schemas = []
    
    @vc_schemas = @vscm.find_schemas
    @brazil_schemas = []
    @app.activities.each do |activity|
      @brazil_schemas << activity.schema
    end
    @schemas = (@vc_schemas + @brazil_schemas).uniq.sort
  end      

  def find_selected_schema schema
    
    source, type = ''
    if @vc_schemas.include? schema
      source = 'subversion'
      type = @vscm.find_schema_type schema
    else
      source = 'brazil'
      activity = @app.activities.where(:schema => schema).limit(1)
      type = activity.db_type 
    end
      
    @schema = {:name => schema, :source => source, :type => type}
  end
  
  def find_db_instances type
    @db_instances = DbInstance.where(:db_type => type)
  end
  
  def set_credentials
    if params[:db_username] && params[:db_password]
        session[:db_credentials] = {:db_username => params[:db_username], :db_password => params[:db_password], :target_schema => params[:target_schema]}
    end
  end

  def fetch_version_info
    @update_versions = []
    @rollback_versions = []
    @version_info = []
    
    @version_info = @db_instance.deployed_versions(session[:db_credentials][:db_username], session[:db_credentials][:db_password], session[:db_credentials][:target_schema]) if session[:db_credentials]
    
    @vscm.find_versions(@schema[:name]).each do |version|
      if version > @version_info[0]
        @update_versions << version
      else
        @rollback_versions << version
      end
    end
  end
end


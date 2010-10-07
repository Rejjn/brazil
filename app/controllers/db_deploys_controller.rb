class DbDeploysController < ApplicationController
  # GET /db_deploys
  # GET /db_deploys.xml
  def index
    @db_deploys = DbDeploy.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @db_deploys }
    end
  end

  # GET /db_deploys/1
  # GET /db_deploys/1.xml
  def show
    @db_deploy = DbDeploy.find(params[:id])
    
    respond_to do |format|
      begin 
        #TODO
        @current_version = @db_deploy.db_instance.find_currently_deployed_schema_version(@db_deploy.db_user, @db_deploy.db_password, @db_deploy.db_schema)
        @update_versions,@rollback_versions = @db_deploy.find_available_versions @current_version
        format.html # show.html.erb
        format.xml  { render :xml => @db_deploy }
      rescue => exception
        compile_grouped_dbi_list
        flash[:error] = "#{exception} (#{exception.class})"
        format.html { render :action => "edit" }
        format.xml  { render :xml => @db_deploy.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /db_deploys/new
  # GET /db_deploys/new.xml
  def new
    compile_grouped_dbi_list
          
    @db_deploy = DbDeploy.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @db_deploy }
    end
  end

  # GET /db_deploys/1/edit
  def edit
    compile_grouped_dbi_list
    
    @db_deploy = DbDeploy.find(params[:id])
  end

  # POST /db_deploys
  # POST /db_deploys.xml
  def create
    @db_deploy = DbDeploy.new(params[:db_deploy])

    respond_to do |format|
      if @db_deploy.save
        flash[:notice] = 'DbDeploy was successfully created.'
        format.html { redirect_to(@db_deploy) }
        format.xml  { render :xml => @db_deploy, :status => :created, :location => @db_deploy }
      else
        compile_grouped_dbi_list
        format.html { render :action => "new" }
        format.xml  { render :xml => @db_deploy.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /db_deploys/1
  # PUT /db_deploys/1.xml
  def update
    @db_deploy = DbDeploy.find(params[:id])

    respond_to do |format|
      if @db_deploy.update_attributes(params[:db_deploy])
        flash[:notice] = 'DbDeploy was successfully updated.'
        format.html { redirect_to(@db_deploy) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @db_deploy.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /db_deploys/1
  # DELETE /db_deploys/1.xml
  def destroy
    @db_deploy = DbDeploy.find(params[:id])
    @db_deploy.destroy

    respond_to do |format|
      format.html { redirect_to(db_deploys_url) }
      format.xml  { head :ok }
    end
  end
  
  # PUT /db_deploys/1/deploy_update
  # PUT /db_deploys/1/deploy_update.xml
  def deploy_update
    respond_to do |format|
      begin 
        @db_deploy = DbDeploy.find(params[:id])
        @run_successfull, @deployment_results = @db_deploy.update_to_version(params[:target_version])
        
        format.html { render :action => "show" }
        format.xml  { head :ok }
      rescue
        flash[:error] = "Failed to deploy database update. (#{$!})"
        #raise $!
                
        format.html { render :action => "show" }
        format.xml  { render :xml => @db_deploy.errors, :status => :unprocessable_entity }
      ensure
        #TODO
        @current_version = @db_deploy.db_instance.find_currently_deployed_schema_version(@db_deploy.db_user, @db_deploy.db_password, @db_deploy.db_schema)
        @update_versions, @rollback_versions = @db_deploy.find_available_versions @current_version
      end
    end
  end
  
  # PUT /db_deploys/1/deploy_rollback
  # PUT /db_deploys/1/deploy_rollback.xml
  def deploy_rollback
    respond_to do |format|
      begin 
        @db_deploy = DbDeploy.find(params[:id])
        @run_successfull, @deployment_results = @db_deploy.rollback_to_version(params[:target_version])
        
        format.html { render :action => "show" }
        format.xml  { head :ok }
      rescue
        flash[:error] = "Failed to deploy database rollback. (#{$!})"
        #raise $!
                
        format.html { render :action => "show" }
        format.xml  { render :xml => @db_deploy.errors, :status => :unprocessable_entity }
      ensure
        
        @current_version = @db_deploy.db_instance.find_currently_deployed_schema_version(@db_deploy.db_user, @db_deploy.db_password, @db_deploy.db_schema)
        @update_versions, @rollback_versions = @db_deploy.find_available_versions @current_version
      end
    end
  end
  
  private
  
  def add_controller_crumbs
    add_crumb 'Database Deploy', db_deploys_path

    if params.has_key?(:id)
      object = DbDeploy.find(params[:id])
      add_crumb object.to_s, db_deploy_path(object)
    end
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
  
end

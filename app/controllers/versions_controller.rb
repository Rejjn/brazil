
require 'brazil/schema_revision'

class VersionsController < ApplicationController
  helper_method :create_update_sql, :create_rollback_sql

  # GET /apps/:app_id/activities/:activity_id/versions
  # GET /apps/:app_id/activities/:activity_id/versions.xml
  # GET /apps/:app_id/activities/:activity_id/versions.atom
  def index
    @activity = Activity.find(params[:activity_id])
    @versions = @activity.versions

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @version }
      format.atom # index.atom.builder
    end
  end

  # GET /apps/:app_id/activities/:activity_id/versions/1
  # GET /apps/:app_id/activities/:activity_id/versions/1.xml
  def show
    @activity = Activity.find(params[:activity_id])
    @version = Version.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @version }
    end
  end

  # GET /apps/:app_id/activities/:activity_id/versions/new
  # GET /apps/:app_id/activities/:activity_id/versions/new.xml
  def new
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.build
    @version.update_sql = Change.activity_sql(params[:activity_id])
    @version.rollback_sql = Change.activity_suggested_rollback_sql(params[:activity_id]) 
    @version_bump_type = Brazil::SchemaRevision::TYPE_MINOR
    
    asvc = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @activity.app.vc_path, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
    @current_lastest = asvc.find_versions(@activity.schema).last
    @version.schema_version = asvc.find_next_schema_version(@activity.schema, @version_bump_type).to_s

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @version }
    end
  end

  # GET /apps/:app_id/activities/:activity_id/versions/1/edit
  def edit
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])
    
    asvc = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @activity.app.vc_path, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
    @current_lastest = asvc.find_versions(@activity.schema).last
  end

  # POST /apps/:app_id/activities/:activity_id/versions.format
  def create
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.build(params[:version])
    if params[:new_version]
      @version.set_schema_version params[:new_version]['major'], params[:new_version]['minor'], params[:new_version]['patch']
    else
      @version.set_schema_version 1, 0, 0
    end
    @version.state = Version::STATE_CREATED

    respond_to do |format|
      if @version.errors.empty? && @version.save
        flash[:notice] = 'Version was successfully created.'
        format.html { redirect_to app_activity_version_path(@activity.app, @activity, @version) }
        format.xml { render :xml => @version, :status => :created, :location => app_activity_version_path(@activity.app, @activity, @version) }
        format.json { render :json => @version, :status => :created, :location => app_activity_version_path(@activity.app, @activity, @version) }
      else
        @version_bump_type = Brazil::SchemaRevision::TYPE_MINOR
        asvc = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @activity.app.vc_path, :vc_uri => ::AppConfig.vc_uri, :vc_tmp_dir => ::AppConfig.vc_dir)
        @current_lastest = asvc.find_versions(@activity.schema).last
        @new_version = asvc.find_next_schema_version(@activity.schema, @version_bump_type)
        
        format.html { render :action => "new" }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
        format.json { render :json => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/:app_id/activities/:activity_id/versions.format
  def update
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])
    @version.attributes = params[:version]
    @version.state = Version::STATE_CREATED
    
    if params[:new_version]
      @version.set_schema_version params[:new_version]['major'], params[:new_version]['minor'], params[:new_version]['patch']
    end

    respond_to do |format|
      if @version.errors.empty? && @version.save
        flash[:notice] = 'Version was successfully updated.'
        format.html { redirect_to app_activity_version_path(@activity.app, @activity, @version) }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
        format.json { render :json => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/:app_id/activities/:activity_id/versions/1/update.format
  def test_update
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])
    
    if (Float(params[:test_db_instance_id]) != nil rescue false)
      @run_successfull, @executed_sql = @version.test_update(params[:test_db_instance_id], params[:test_schema], params[:db_username], params[:db_password])
    else
      @version.errors.add_to_base("Please select a Test Database!")
    end

    respond_to do |format|
      if @version.errors.empty? && @run_successfull
        flash[:notice] = "Executed Update SQL"
        format.html { render :action => 'show' }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        flash[:error] = "Failed to execute Update SQL"
        format.html { render :action => 'show' }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
        format.json { render :json => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/:app_id/activities/:activity_id/versions/1/rollback.format
  def test_rollback
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])

    if (Float(params[:test_db_instance_id]) != nil rescue false)    
      @run_successfull, @executed_sql = @version.test_rollback(params[:test_db_instance_id], params[:test_schema], params[:db_username], params[:db_password])
    else
      @version.errors.add_to_base("Please select a Test Database!")
    end

    respond_to do |format|
      if @version.errors.empty? && @run_successfull
        flash[:notice] = "Executed Rollback SQL"
        format.html { render :action => 'show' }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        flash[:error] = "Failed to execute Rollback SQL"
        format.html { render :action => 'show' }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
        format.json { render :json => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/:app_id/activities/:activity_id/versions/1/deploy.format
  def upload
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])

    respond_to do |format|
      begin 
        @version.add_to_version_control(params[:vc_username], params[:vc_password])
        
        flash[:notice] = "Successfully uploaded version '#{@version}' to the source version control repos"
        format.html { render :action => 'show' }
        format.xml  { head :ok }
        format.json  { head :ok }
      rescue => e
        flash[:error] = "Failed to upload version '#{@version}' to source version control! (#{e})"
        format.html { render :action => 'show' }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
        format.json { render :json => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/:app_id/activities/:activity_id/versions/1/remove.format
  def remove
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])

    if @version.deployed?
      format.html { render :action => 'show' }
    end

    respond_to do |format|
      begin 
        @version.delete_from_version_control(params[:vc_username], params[:vc_password])
        
        flash[:notice] = "Successfully removed version '#{@version}' from the source version control repos"
        format.html { redirect_to app_activity_version_path(@activity.app, @activity, @version) }
        format.xml  { head :ok }
        format.json  { head :ok }
      rescue => e
        flash[:error] = "Failed to remove version '#{@version}' from source version control! (#{e})"
        format.html { render :action => 'show' }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
        format.json { render :json => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/:app_id/activities/:activity_id/versions/1/deployed.format
  def deployed
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])
    @activity.deployed!
    @version.deployed!

    respond_to do |format|
      if @version.save && @activity.save
        flash[:notice] = "Version '#{@version}' is now set as deployed"
        format.html { redirect_to app_activity_version_path(@activity.app, @activity, @version) }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => 'show' }
        format.xml  { render :xml => @version.errors, :status => :unprocessable_entity }
        format.json { render :json => @version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /apps/:app_id/activities/:activity_id/versions/1/delete
  def delete
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])
  end

  # DELETE /apps/:app_id/activities/:activity_id/versions/1
  def destroy
    @activity = Activity.find(params[:activity_id])
    @version = @activity.versions.find(params[:id])

    if params[:version_delete_cancel]
      redirect_to app_activity_version_path(@activity.app, @activity, @version)
      return
    end

    respond_to do |format|
      if @version.destroy
        format.html do
          flash[:notice] = "Version '#{@version}' successfully deleted"
          if @activity.versions.count == 0
            @activity.development!
            redirect_to app_activity_path(@activity.app, @activity)
          else
            redirect_to app_activity_versions_path(@activity.app, @activity)
          end
        end
      else
        format.html { render :action => 'delete' }
      end
    end

  end

  private

  def create_update_sql(version)
    SqlController.new.update_sql version
  end

  def create_rollback_sql(version)
    SqlController.new.rollback_sql version
  end

  def add_controller_crumbs
    app = App.find(params[:app_id])
    activity = app.activities.find(params[:activity_id])

    add_app_controller_crumbs(app)
    add_activities_controller_crumbs(app, activity)

    add_crumb 'Versions', app_activity_versions_path(app, activity)

    if params.has_key?(:id)
      version = activity.versions.find(params[:id])
      add_crumb version.to_s, app_activity_version_path(app, activity, version)
    end
  end
end

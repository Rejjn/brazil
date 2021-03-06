class ActivitiesController < ApplicationController
  
  respond_to :html, :xml
  
  # GET /apps/:app_id/activities
  # GET /apps/:app_id/activities.xml
  # GET /apps/:app_id/activities.atom
  def index
    @app = App.find(params[:app_id])
    @activities = @app.activities.all(:order => 'updated_at DESC')
    @activity = @app.activities.build
    @base_versions = [Activity::NO_BASE_VERSION]

    respond_to do |format|
      format.html do # index.html.erb
        if request.xhr?
          render :partial => 'index', :locals => {:app => @app, :activities => @activities}
        end
      end
      format.xml  { render :xml => @activities }
      format.atom # index.atom.builder
    end
  end

  # GET /apps/:app_id/activities/1
  # GET /apps/:app_id/activities/1.xml
  # GET /apps/:app_id/activities/1.atom
  def show
    @app = App.find(params[:app_id])
    @activity = @app.activities.find(params[:id])
    @change = @activity.changes.build

    latest_change = Change.first(:conditions => {:activity_id => params[:id], :state => [Change::STATE_EXECUTED, Change::STATE_SAVED]}, :order => 'created_at DESC')
    if latest_change
      @change.developer = latest_change.developer
    end
    
    latest_base_version?

    respond_to do |format|
      format.html do # show.html.erb
        if request.xhr?
          render :partial => "shared/activity", :locals => {:activity => @activity}
        end
      end
      format.xml  { render :xml => @activity }
      format.atom # show.atom.builder
    end
  end

  # GET /apps/:app_id/activities/new
  # GET /apps/:app_id/activities/new.xml
  def new
    @app = App.find(params[:app_id])
    @activity = @app.activities.build
    @base_versions = [Activity::NO_BASE_VERSION]

    respond_to do |format|
      format.html do # new.html.erb
        render :layout => false if request.xhr?
      end
      format.xml  { render :xml => @activity }
    end
  end

  # GET /apps/:app_id/activities/1/edit
  def edit
    @app = App.find(params[:app_id])
    @activity = @app.activities.find(params[:id])
    
    @vscm = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @app.vc_path, :vc_uri => ::AppConfig.vc_uri)    
    @base_versions = @vscm.find_versions(@activity.schema)
    @base_versions << Activity::NO_BASE_VERSION if @base_versions.count == 0
    
    render :layout => false if request.xhr?
  end

  # POST /apps/:app_id/activities
  # POST /apps/:app_id/activities.xml
  def create
    @app = App.find(params[:app_id])
    @activity = @app.activities.build(params[:activity])
    @activity.state = Activity::STATE_DEVELOPMENT

    respond_to do |format|
      if @activity.save
        flash[:notice] = 'Activity was successfully created.'
        format.html do
          if request.xhr?
            render :partial => 'shared/activity_row', :collection => @app.activities, :as => 'activity'
          else
            redirect_to app_activity_path(@app, @activity)
          end
        end
        format.xml  { render :xml => @activity, :status => :created, :location => @activity }
      else
        format.html do
          @base_versions = ['1_1_0']
          
          if request.xhr?
            render :partial => 'new', :locals => {:activity => @activity, :app => @app}, :status => :unprocessable_entity
          else
            render :action => "new"
          end
        end
        format.xml  { render :xml => @activity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/:app_id/activities/1
  # PUT /apps/:app_id/activities/1.xml
  def update
    @app = App.find(params[:app_id])
    @activity = @app.activities.find(params[:id])

    if params[:cancel_edit_activity_button]
      respond_to do |format|
        format.html do
          if request.xhr? 
            render :partial => 'shared/activity', :locals => { :activity => @activity }
          else
            redirect_to apps_url
          end
        end
        
        format.xml  { head :ok }
      end
          
      return
    end

    @vscm = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @app.vc_path, :vc_uri => ::AppConfig.vc_uri)    
    @base_versions = @vscm.find_versions(params[:arg])
    @base_versions << Activity::NO_BASE_VERSION if @base_versions.count == 0

    respond_to do |format|
      if @activity.update_attributes(params[:activity])
        flash[:notice] = 'Activity was successfully updated.'
        format.html do
          if request.xhr?
            render :partial => "shared/activity", :locals => {:activity => @activity}
          else
            redirect_to app_activity_path(@app, @activity)
          end
        end
        format.xml  { head :ok }
      else
        format.html do
          if request.xhr?
            render :action => "edit", :layout => false, :status => :unprocessable_entity
          else
            render :action => "edit"
          end
        end
        format.xml  { render :xml => @activity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE 
  # DELETE 
  def destroy
    @activity = Activity.find(params[:id])
    
    if params[:activity_app_delete_cancel]
      redirect_to app_activity_path(@activity.app, @activity)
      return
    end

    @activity.destroy
    respond_with(@activity, :location => app_activities_url)
  end
  
  def execute
    @app = App.find(params[:app_id])
    @activity = Activity.find(params[:id])

    begin 
      @run_successfull, @deployment_results = @activity.execute
    
      if @run_successfull
        flash[:notice] = 'Activity SQL successfully executed'
      else
        flash[:error] = 'Failed to fully execyte activity SQL (see below for more info)'
      end
      
      respond_to do |format|
        if request.xhr?
          @change = @activity.changes.build
          format.html { render :partial => "changes/changes", :locals => {:activity => @activity, :change => @change, :deployment_results => @deployment_results }}
          #format.html { render :partial => "changes/changes", :collection => @activity.changes } 
        else
          latest_base_version?
          @change = @activity.changes.build
          format.html { render :action => 'show' }
        end
        
        format.xml  { render :xml => @activity }
      end      
    rescue => e
      flash[:error] = "Error while executing activity SQL (#{e})"
      
      respond_to do |format|
        if request.xhr?
          @change = @activity.changes.build
          format.html { render :partial => "changes/changes", :locals => {:activity => @activity, :change => @change, :deployment_results => @deployment_results}} 
        else 
          format.html { redirect_to app_activity_path(@app, @activity) }
        end
        
        format.xml  { render :xml => @activity }
      end
    end
  end

  def base_versions
    @app = App.find(params[:app_id])
    respond_to do |format|
      begin
        @vscm = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @app.vc_path, :vc_uri => ::AppConfig.vc_uri)    
        @base_versions = @vscm.find_versions(params[:arg])
        
        if @base_versions.count == 0
          @base_versions << Activity::NO_BASE_VERSION
        end
        
        format.html { render :layout =>  false } 
        format.xml  { render :xml => @base_versions }
      rescue => e
        flash[:error] = "Failed to load base versions (#{e})"
        @base_versions = []
        format.html { render :layout =>  false, :status => :unprocessable_entity }
        format.xml  { render :xml => 'Error', :status => :unprocessable_entity }
      end
    end      
  end 

  def delete
    @app = App.find(params[:app_id])
    @activity = @app.activities.find(params[:id])
    
    respond_with(@activity)
  end


  def reset
    @app = App.find(params[:app_id])
    @activity = @app.activities.find(params[:id])

    respond_to do |format|
      begin 
        @activity.reset
        
        flash[:notice] = 'Activity developer database successfully reset.'
        format.html do
          if request.xhr?
            @change = @activity.changes.build
            render :partial => "changes/changes", :locals => {:activity => @activity, :change => @change}
          else
            redirect_to app_activity_path(@app, @activity)
          end
        end
        format.xml  { head :ok }
      rescue => e
        flash[:error] = "Failed to reset activity developer database (#{e})."
        
        format.html do
          if request.xhr?
            @change = @activity.changes.build
            render :partial => "changes/changes", :locals => {:activity => @activity, :change => @change}
          else
            latest_base_version?
            @change = @activity.changes.build
            render :action => "show"
          end
        end
        format.xml  { render :xml => @activity.errors, :status => :unprocessable_entity }
      end
    end
    
  end

  private

  def latest_base_version?
    unless @base_versions
      @vscm = Brazil::AppSchemaVersionControl.new(:vc_type => Brazil::AppSchemaVersionControl::TYPE_SUBVERSION, :vc_path => @app.vc_path, :vc_uri => ::AppConfig.vc_uri) unless @vscm    
      @base_versions = @vscm.find_versions(@activity.schema)
    end
    
    unless @base_versions.empty? || @activity.base_version == @base_versions.last.to_s
      flash[:warning] = "Note: the chosen base version is not the latest found in the version control repos!"
    end
  end

  def add_controller_crumbs
    app = App.find(params[:app_id])
    add_app_controller_crumbs(app)

    if params.has_key?(:id)
      add_activities_controller_crumbs(app, app.activities.find(params[:id]))
    else
      add_activities_controller_crumbs(app, nil)
    end
  end
end

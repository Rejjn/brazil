
class ChangesController < ApplicationController

  respond_to :html, :xml
    
  # GET /apps/:app_id/activities/:activity_id/changes.xml
  def index
    @activity = Activity.find(params[:activity_id])
    @changes = @activity.changes

    respond_to do |format|
      format.xml  { render :xml => @changes }
    end
  end

  # GET /apps/:app_id/activities/:activity_id/changes/1.xml
  def show
    @activity = Activity.find(params[:activity_id])
    @change = @activity.changes.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @change }
    end
  end

  # GET /apps/:app_id/activities/:activity_id/changes/new.xml
  def new
    @activity = Activity.find(params[:activity_id])
    @change = @activity.changes.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @change }
    end
  end

  # POST /apps/:app_id/activities/:activity_id/changes.format
  def create
    @activity = Activity.find(params[:activity_id])
    @change = @activity.changes.build(params[:change])
    @change.developer = session[:user]
    @change.state = Change::STATE_SAVED
    
    respond_to do |format|
      if @change.save

        if params[:create_change_execute_button]
          @run_successfull, @deployment_results = @change.execute()
        end
        
        flash[:notice] = 'Database change was successfully created.'
        format.html do
          if request.xhr?
            @change = @activity.changes.build
            render :partial => "changes", :locals => {:activity => @activity, :change => @change, :deployment_results => @deployment_results}
          else
            render :action => 'show'
          end
        end
        format.xml  { render :xml => @change, :status => :created, :location => app_activity_change_path(@activity.app, @activity, @change) }
        format.json  { render :json => @change, :status => :created, :location => app_activity_change_path(@activity.app, @activity, @change) }
      else
        format.html do
          if request.xhr?
            render :partial => "new", :locals => {:change => @change, :activity => @activity}, :status => :unprocessable_entity
          else
            render :action => "new"
          end
        end
        format.xml  { render :xml => @change.errors, :status => :unprocessable_entity }
        format.json  { render :json => @change.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /apps/:app_id/activities/:activity_id/changes/:change_id/edit
  # GET /apps/:app_id/activities/:activity_id/changes/:change_id/edit.xml
  def edit
    @activity = Activity.find(params[:activity_id])
    @change = @activity.changes.find(params[:id])

    respond_to do |format|
      format.html do # edit.html.erb
        render :layout => false if request.xhr?
      end
      format.xml  { render :xml => @change }
    end
  end

  # PUT /apps/:app_id/activities/:activity_id/changes/:id.format
  def update
    @activity = Activity.find(params[:activity_id])
    @change = @activity.changes.find(params[:id])
    @change.attributes = params[:change]
    @change.state = Change::STATE_SAVED
    
    respond_to do |format|
      if @change.save
        
        if params[:create_change_execute_button]
          @run_successfull, @deployment_results = @change.execute()
        end        
        
        flash[:notice] = 'Change was successfully updated.'
        format.html do
          if request.xhr?
            @change = @activity.changes.build
            render :partial => "changes", :locals => {:activity => @activity, :change => @change, :deployment_results => @deployment_results}
          else
            redirect_to app_activity_path(@activity.app, @activity)
          end
        end
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html do
          if request.xhr?
            render :action => "edit", :layout => false, :status => :unprocessable_entity
          else
            render :action => "edit"
          end
        end
        format.xml  { render :xml => @change.errors, :status => :unprocessable_entity }
        format.json  { render :json => @change.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE
  # DELETE
  def destroy
    @change = Change.find(params[:id])
    @activity = @change.activity

    if params[:change_activity_app_delete_cancel]
      redirect_to app_activity_path(@activity.app, @activity)
      return
    end

    @change.destroy
    flash[:notice] = 'Change successfully deleted'
    respond_with([@activity.app, @activity])
  end

  def execute
    @activity = Activity.find(params[:activity_id])
    @change = @activity.changes.find(params[:id])
    @executed_change_id = @change.id

    begin 
      @run_successfull, @deployment_results = @change.execute
    
      if @run_successfull
        flash[:notice] = 'Change SQL successfully executed'
      else
        flash[:error] = 'Failed to fully execute change SQL (see above for more info)'
      end
      
      respond_to do |format|
        if request.xhr?
          @change = @activity.changes.build
          format.html { render :partial => "changes/changes", :locals => {:activity => @activity, :change => @change, :deployment_results => @deployment_results }}
        else 
          format.html { render :action => 'show' }
        end
        
        format.xml  { render :xml => @change }
      end      
    rescue => e
      flash[:error] = "Error while executing activity SQL (#{e})"
      
      respond_to do |format|
        if request.xhr?
          @change = @activity.changes.build
          format.html { render :partial => "changes/changes", :locals => {:activity => @activity, :change => @change, :deployment_results => @deployment_results}} 
        else 
          format.html { render :action => 'show' }
        end
        
        format.xml  { render :xml => @change }
      end
    end
  end

  def delete
    @activity = Activity.find(params[:activity_id])
    @change = @activity.changes.find(params[:id])

    respond_with(@change)
  end

  private

  def add_controller_crumbs
    app = App.find(params[:app_id])
    add_app_controller_crumbs(app)
    add_activities_controller_crumbs(app, app.activities.find(params[:activity_id]))

    add_crumb 'Changes'

    if params.has_key?(:id)
      add_crumb app.activities.find(params[:activity_id]).changes.find(params[:id]).to_s
    end
  end
end

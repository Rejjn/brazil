class AppsController < ApplicationController
  # GET /apps
  # GET /apps.xml
  # GET /apps.atom
  def index
    @apps = App.all(:order => 'name ASC')
    @app = App.new

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @apps }
      format.atom # index.atom.builder
    end
  end

  # GET /apps/1
  # GET /apps/1.xml
  def show
    @app = App.find(params[:id])

    respond_to do |format|
      format.html do # show.html.erb
        if request.xhr?
          render :partial => 'app', :locals => {:app => @app}
        end
      end
      format.xml  { render :xml => @app }
    end
  end

  # GET /apps/new
  # GET /apps/new.xml
  def new
    @app = App.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @app }
    end
  end

  # GET /apps/1/edit
  def edit
    @app = App.find(params[:id])

    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => 'edit_horizontal', :locals => {:app => @app}
        end
      end
    end
  end

  # POST /apps
  # POST /apps.xml
  def create
    @app = App.new(params[:app])

    respond_to do |format|
      if @app.save
        flash[:notice] = 'App was successfully created.'
        format.html { redirect_to app_activities_path(@app) }
        format.xml  { render :xml => @app, :status => :created, :location => @app }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /apps/1
  # PUT /apps/1.xml
  def update
    @app = App.find(params[:id])

    if params[:cancel_edit_app_button]
      respond_to do |format|
        format.html do
          if request.xhr? 
            render :partial => 'app', :locals => { :app => @app }
          else
            redirect_to apps_url
          end
        end
        
        format.xml  { head :ok }
      end
          
      return
    end

    respond_to do |format|
      if @app.update_attributes(params[:app])
        format.html do
          if request.xhr?
            render :partial => 'app', :locals => {:app => @app}
          else
            flash[:notice] = 'App was successfully updated.'
            redirect_to app_activities_path(@app)
          end
        end
        format.xml  { head :ok }
      else
        format.html do
          if request.xhr?
            render :partial => 'edit_horizontal', :locals => {:app => @app}
          else
            render :action => 'edit'
          end
        end
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def delete
    @app = App.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { head :ok }
    end
  end

  # DELETE /db_deploys/1
  # DELETE /db_deploys/1.xml
  def destroy
    @app = App.find(params[:id])
    
    if params[:app_delete_cancel]
      redirect_to apps_url
      return
    end

    respond_to do |format|
      if @app.destroy
        format.html do
          flash[:notice] = "App '#{@app}' successfully deleted"
          redirect_to apps_url
        end
        format.xml  { head :ok }
      else
        format.html { render :action => 'delete' }
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def add_controller_crumbs
    add_crumb 'Apps', apps_path

    if params.has_key?(:id)
      object = App.find(params[:id])
      add_crumb object.to_s, app_path(object)
    end
  end
end

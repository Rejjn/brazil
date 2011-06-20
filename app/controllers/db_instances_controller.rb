class DbInstancesController < ApplicationController
  
  respond_to :html, :xml
  
  # GET /db_instances
  # GET /db_instances.xml
  def index
    @db_instances = DbInstance.all(:order => 'db_env, db_alias', :conditions => {:db_env => [DbInstance::ENV_DEV, DbInstance::ENV_TEST]})
    @db_instances_prod = DbInstance.all(:order => 'db_env, db_alias', :conditions => {:db_env => DbInstance::ENV_PROD})

    respond_with @db_instances
  end

  # GET /db_instances/1
  # GET /db_instances/1.xml
  def show
    @db_instance = DbInstance.find(params[:id])

    respond_with @db_instance
  end

  # GET /db_instances/new
  # GET /db_instances/new.xml
  def new
    @db_instance = DbInstance.new

    respond_with @db_instance
  end

  # GET /db_instances/1/edit
  def edit
    @db_instance = DbInstance.find(params[:id])
    
    respond_with @db_instance
  end

  # POST /db_instances
  # POST /db_instances.xml
  def create
    @db_instance = DbInstance.new(params[:db_instance])

    @db_instance.save
    respond_with @db_instance
  end

  # PUT /db_instances/1
  # PUT /db_instances/1.xml
  def update
    @db_instance = DbInstance.find(params[:id])

    respond_to do |format|
      if @db_instance.update_attributes(params[:db_instance])
        flash[:notice] = 'Database instance was successfully updated.'
        format.html { redirect_to db_instances_path }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @db_instance.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /db_instances/1/delete
  def delete
    @db_instance = DbInstance.find(params[:id])
  end

  # DELETE /db_instances/1
  # DELETE /db_instances/1.xml
  def destroy
    @db_instance = DbInstance.find(params[:id])

    if params[:db_instance_delete_cancel]
      redirect_to db_instances_path
      return
    end

    respond_to do |format|
      if @db_instance.destroy
        format.html do
          flash[:notice] = "Database Instance '#{@db_instance}' successfully deleted"
          redirect_to db_instances_path
        end
        format.xml  { head :ok }
      else
        format.html { render :action => 'delete' }
        format.xml  { render :xml => @db_instance.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def add_controller_crumbs
    add_crumb 'Database Instances', db_instances_path

    if params.has_key?(:id)
      object = DbInstance.find(params[:id])
      add_crumb object.to_s, db_instance_path(object)
    end
  end
end

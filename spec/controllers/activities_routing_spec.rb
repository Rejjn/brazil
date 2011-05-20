require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActivitiesController do
  describe "named route generation" do
    it "should map 'app_activities_path' to /apps/1/activities" do
      {:get => app_activities_path(1)}.should == {:get => '/apps/1/activities'}
    end
    
    it "should map 'new_app_activity_path' to /apps/1/activities/new" do
      {:get => new_app_activity_path(1)}.should == {:get => '/apps/1/activities/new'}
    end

    it "should map 'app_activity_path(1, 2)' to /apps/1/activities/2" do
      {:get => app_activity_path(1, 2)}.should == {:get => '/apps/1/activities/2'}
    end
    
    it "should map 'edit_app_activity_path(1, 2)' to /apps/1/activities/2/edit" do
      {:get => edit_app_activity_path(1, 2)}.should == {:get => '/apps/1/activities/2/edit'}
    end
    
    it "should map 'delete_app_activity_path(1, 2)' to /apps/1/activities/2/delete" do
      {:get => delete_app_activity_path(1, 2)}.should == {:get => '/apps/1/activities/2/delete'}
    end
    
    it "should map 'execute_app_activity_path(1, 2)' to /apps/1/activities/2/execute" do
      {:post => execute_app_activity_path(1, 2)}.should == {:post => '/apps/1/activities/2/execute'}
    end
  end

  describe "route recognition" do
    it "should map GET /apps/1/activities to { :controller => 'activities', :action => 'index', :app_id => '1' }" do
      { :get => "/apps/1/activities" }.should route_to(:controller => 'activities', :action => 'index', :app_id => '1')      
    end

    it "should map GET /apps/1/activities/new to { :controller => 'activities', :action => 'new', :app_id => '1' }" do
      { :get => "/apps/1/activities/new" }.should route_to(:controller => 'activities', :action => 'new', :app_id => '1')
    end

    it "should map POST /apps/1/activities to { :controller => 'activities', :action => 'create', :app_id => '1' }" do
      { :post => "/apps/1/activities" }.should route_to(:controller => 'activities', :action => 'create', :app_id => '1')
    end

    it "should map GET /apps/1/activities/2 to { :controller => 'activities', :action => 'show', :app_id => '1', :id => 2 }" do
      { :get => "/apps/1/activities/2" }.should route_to(:controller => 'activities', :action => 'show', :app_id => '1', :id => '2')
    end

    it "should map GET /apps/1/activities/2/edit to { :controller => 'activities', :action => 'edit', :app_id => '1', :id => 2 }" do
      { :get => "/apps/1/activities/2/edit" }.should route_to(:controller => 'activities', :action => 'edit', :app_id => '1', :id => '2')
    end

    it "should map PUT /apps/1/activities/2 to { :controller => 'activities', :action => 'update', :app_id => '1', :id => 2 }" do
      { :put => "/apps/1/activities/2" }.should route_to(:controller => 'activities', :action => 'update', :app_id => '1', :id => '2')
    end

    it "should map DELET /apps/1/activities/2 to { :controller => 'activities', :action => 'destroy', :app_id => '1', :id => 2 }" do
      { :delete => "/apps/1/activities/2" }.should route_to(:controller => 'activities', :action => 'destroy', :app_id => '1', :id => '2')
    end
    
    it "should map POST /apps/1/activities/2/execute to { :controller => 'activities', :action => 'execute', :app_id => '1' }" do
      { :post => "/apps/1/activities/2/execute" }.should route_to(:controller => 'activities', :action => 'execute', :app_id => '1', :id => '2')
    end

    it "should map GET /apps/1/activities/2/delete to { :controller => 'activities', :action => 'create', :app_id => '1' }" do
      { :get => "/apps/1/activities/2/delete" }.should route_to(:controller => 'activities', :action => 'delete', :app_id => '1', :id => '2')
    end
  end
end

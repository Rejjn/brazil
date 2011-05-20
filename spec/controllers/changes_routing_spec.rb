require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChangesController do
  describe "named route generation" do
    it "should map 'app_activity_changes_path(1, 2)' to /apps/1/activities/2/changes" do
      {:get => app_activity_changes_path(1, 2)}.should == {:get => '/apps/1/activities/2/changes'}
    end
    
    it "should map 'new_app_activity_change_path(1, 2)' to /apps/1/activities/2/changes/new" do
      {:get => new_app_activity_change_path(1, 2)}.should == {:get => '/apps/1/activities/2/changes/new'}
    end

    it "should map 'app_activity_change_path(1, 2, 3)' to /apps/1/activities/2/changes/3" do
      {:get => app_activity_change_path(1, 2, 3)}.should == {:get => '/apps/1/activities/2/changes/3'}
    end
    
    it "should map 'edit_app_activity_change_path(1, 2, 3)' to /apps/1/activities/2/changes/3/edit" do
      {:get => edit_app_activity_change_path(1, 2, 3)}.should == {:get => '/apps/1/activities/2/changes/3/edit'}
    end
    
    it "should map 'delete_app_activity_changes_path(1, 2, 3)' to /apps/1/activities/2/changes/3/delete" do
      {:get => delete_app_activity_change_path(1, 2, 3)}.should == {:get => '/apps/1/activities/2/changes/3/delete'}
    end
    
    it "should map 'execute_app_activity_changes_path(1, 2, 3)' to /apps/1/activities/2/changes/3/execute" do
      {:post => execute_app_activity_change_path(1, 2, 3)}.should == {:post => '/apps/1/activities/2/changes/3/execute'}
    end
  end

  describe "route recognition" do
    it "should map GET /apps/1/activities/2/changes to { :controller => 'changes', :action => 'index', :app_id => '1', :activity_id => '2' }" do
      { :get => "/apps/1/activities/2/changes" }.should route_to( :controller => 'changes', :action => 'index', :app_id => '1', :activity_id => '2' )      
    end

    it "should map GET /apps/1/activities/2/changes/new to { :controller => 'changes', :action => 'new', :app_id => '1', :activity_id => '2' }" do
      { :get => "/apps/1/activities/2/changes/new" }.should route_to(:controller => 'changes', :action => 'new', :app_id => '1', :activity_id => '2')
    end

    it "should map POST /apps/1/activities/2/changes to { :controller => 'changes', :action => 'create', :app_id => '1', :activity_id => '2' }" do
      { :post => "/apps/1/activities/2/changes" }.should route_to(:controller => 'changes', :action => 'create', :app_id => '1', :activity_id => '2')
    end

    it "should map GET /apps/1/activities/2/changes/3 to { :controller => 'changes', :action => 'show', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :get => "/apps/1/activities/2/changes/3" }.should route_to(:controller => 'changes', :action => 'show', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map GET /apps/1/activities/2/changes/3/edit to { :controller => 'changes', :action => 'edit', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :get => "/apps/1/activities/2/changes/3/edit" }.should route_to(:controller => 'changes', :action => 'edit', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map PUT /apps/1/activities/2/changes/3 to { :controller => 'changes', :action => 'update', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :put => "/apps/1/activities/2/changes/3" }.should route_to(:controller => 'changes', :action => 'update', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map DELET /apps/1/activities/2/changes/3 to { :controller => 'changes', :action => 'destroy', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :delete => "/apps/1/activities/2/changes/3" }.should route_to(:controller => 'changes', :action => 'destroy', :app_id => '1', :activity_id => '2', :id => '3')
    end
    
    it "should map POST /apps/1/activities/2/changes/3/execute to { :controller => 'changes', :action => 'execute', :app_id => '1', :activity_id => '2' }" do
      { :post => "/apps/1/activities/2/changes/3/execute" }.should route_to(:controller => 'changes', :action => 'execute', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map GET /apps/1/activities/2/changes/3/delete to { :controller => 'changes', :action => 'delete', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :get => "/apps/1/activities/2/changes/3/delete" }.should route_to(:controller => 'changes', :action => 'delete', :app_id => '1', :activity_id => '2', :id => '3')
    end
  end
end

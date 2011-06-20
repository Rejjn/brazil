require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VersionsController do
  describe "named route generation" do
    it "should map 'app_activity_versions_path(1, 2)' to /apps/1/activities/2/versions" do
      {:get => app_activity_versions_path(1, 2)}.should == {:get => '/apps/1/activities/2/versions'}
    end
    
    it "should map 'new_app_activity_version_path' to /apps/1/activities/new" do
      {:get => new_app_activity_version_path(1, 2)}.should == {:get => '/apps/1/activities/2/versions/new'}
    end

    it "should map 'app_activity_version_path(1, 2, 3)' to /apps/1/activities/2/versions/3" do
      {:get => app_activity_version_path(1, 2, 3)}.should == {:get => '/apps/1/activities/2/versions/3'}
    end
    
    it "should map 'edit_app_activity_version_path(1, 2, 3)' to /apps/1/activities/2/versions/3/edit" do
      {:get => edit_app_activity_version_path(1, 2, 3)}.should == {:get => '/apps/1/activities/2/versions/3/edit'}
    end
    
    it "should map 'delete_app_activity_version_path(1, 2, 3)' to /apps/1/activities/2/versions/3/delete" do
      {:get => delete_app_activity_version_path(1, 2, 3)}.should == {:get => '/apps/1/activities/2/versions/3/delete'}
    end
    
    it "should map 'update_app_activity_version_path(1, 2, 3)' to /apps/1/activities/2/versions/3" do
      {:post => app_activity_version_path(1, 2, 3)}.should == {:post => '/apps/1/activities/2/versions/3'}
    end

    it "should map 'test_update_app_activity_version_path(1, 2, 3)' to /apps/1/activities/2/versions/3/test_update" do
      {:post => test_update_app_activity_version_path(1, 2, 3)}.should == {:post => '/apps/1/activities/2/versions/3/test_update'}
    end

    it "should map 'test_rollback_app_activity_version_path(1, 2, 3)' to /apps/1/activities/2/versions/3/test_rollback" do
      {:post => test_rollback_app_activity_version_path(1, 2, 3)}.should == {:post => '/apps/1/activities/2/versions/3/test_rollback'}
    end

    it "should map 'upload_app_activity_version_path(1, 2)' to /apps/1/activities/2/versions/3/upload" do
      {:post => upload_app_activity_version_path(1, 2, 3)}.should == {:post => '/apps/1/activities/2/versions/3/upload'}
    end

    it "should map 'deploy_app_activity_version_path(1, 2)' to /apps/1/activities/2/versions/3/deployed" do
      {:post => deployed_app_activity_version_path(1, 2, 3)}.should == {:post => '/apps/1/activities/2/versions/3/deployed'}
    end
  end

  describe "route recognition" do
    it "should map GET /apps/1/activities/2/versions to { :controller => 'versions', :action => 'index', :app_id => '1', :activity_id => '2' }" do
      { :get => "/apps/1/activities/2/versions" }.should route_to(:controller => 'versions', :action => 'index', :app_id => '1', :activity_id => '2')      
    end

    it "should map GET /apps/1/activities/2/versions/new to { :controller => 'versions', :action => 'new', :app_id => '1', :activity_id => '2' }" do
      { :get => "/apps/1/activities/2/versions/new" }.should route_to(:controller => 'versions', :action => 'new', :app_id => '1', :activity_id => '2')
    end

    it "should map POST /apps/1/activities/2/versions to { :controller => 'versions', :action => 'create', :app_id => '1', :activity_id => '2' }" do
      { :post => "/apps/1/activities/2/versions" }.should route_to(:controller => 'versions', :action => 'create', :app_id => '1', :activity_id => '2')
    end

    it "should map GET /apps/1/activities/2/versions/3 to { :controller => 'versions', :action => 'show', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :get => "/apps/1/activities/2/versions/3" }.should route_to(:controller => 'versions', :action => 'show', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map GET /apps/1/activities/2/versions/3/edit to { :controller => 'versions', :action => 'edit', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :get => "/apps/1/activities/2/versions/3/edit" }.should route_to(:controller => 'versions', :action => 'edit', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map PUT /apps/1/activities/2/versions/3 to { :controller => 'versions', :action => 'update', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :put => "/apps/1/activities/2/versions/3" }.should route_to(:controller => 'versions', :action => 'update', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map DELET /apps/1/activities/2/versions/3 to { :controller => 'versions', :action => 'destroy', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :delete => "/apps/1/activities/2/versions/3" }.should route_to(:controller => 'versions', :action => 'destroy', :app_id => '1', :activity_id => '2', :id => '3')
    end
    
    it "should map GET /apps/1/activities/2/versions/3/delete to { :controller => 'versions', :action => 'delete', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :get => "/apps/1/activities/2/versions/3/delete" }.should route_to(:controller => 'versions', :action => 'delete', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map POST /apps/1/activities/2/versions/3 to { :controller => 'versions', :action => 'update', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :put => "/apps/1/activities/2/versions/3" }.should route_to(:controller => 'versions', :action => 'update', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map POST /apps/1/activities/2/versions/3/test_update to { :controller => 'versions', :action => 'test_update', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :post => "/apps/1/activities/2/versions/3/test_update" }.should route_to(:controller => 'versions', :action => 'test_update', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map POST /apps/1/activities/2/versions/3/test_rollback to { :controller => 'versions', :action => 'test_rollback', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :post => "/apps/1/activities/2/versions/3/test_rollback" }.should route_to(:controller => 'versions', :action => 'test_rollback', :app_id => '1', :activity_id => '2', :id => '3')
    end

    it "should map POST /apps/1/activities/2/versions/3/upload to { :controller => 'versions', :action => 'upload', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :post => "/apps/1/activities/2/versions/3/upload" }.should route_to(:controller => 'versions', :action => 'upload', :app_id => '1', :activity_id => '2', :id => '3')
    end
    
    it "should map POST /apps/1/activities/2/versions/3/deployed to { :controller => 'versions', :action => 'deployed', :app_id => '1', :activity_id => '2', :id => '3' }" do
      { :post => "/apps/1/activities/2/versions/3/deployed" }.should route_to(:controller => 'versions', :action => 'deployed', :app_id => '1', :activity_id => '2', :id => '3')
    end
  end
end

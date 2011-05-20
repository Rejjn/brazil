require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppsController do
  describe "named route generation" do
    it "should map 'apps_path' to /apps" do
      {:get => apps_path}.should == {:get => '/apps'}
    end
    
    it "should map 'new_app_path' to /apps/new" do
      {:get => new_app_path}.should == {:get => '/apps/new'}
    end

    it "should map 'app_path(:id => 1)' to /apps/1" do
      {:get => app_path(1)}.should == {:get => '/apps/1'}
    end
    
    it "should map 'edit_app_path(:id => 1)' to /apps/1/edit" do
      {:get => edit_app_path(1)}.should == {:get => '/apps/1/edit'}
    end
    
    it "should map 'delete_app_path(:id => 1)' to /apps/1/delete" do
      {:get => delete_app_path(1)}.should == {:get => '/apps/1/delete'}
    end
  end

  describe "route recognition" do
    it "should map GET '/apps' to { :controller => 'apps', :action => 'index' }" do
      { :get => "/apps" }.should route_to(:controller => "apps", :action => "index")      
    end

    it "should map GET /apps/new to { :controller => 'apps', :action => 'new' }" do
      { :get => "/apps/new" }.should route_to(:controller => "apps", :action => "new")
    end

    it "should map POST /apps to { :controller => 'apps', :action => 'create' }" do
      { :post => "/apps" }.should route_to(:controller => "apps", :action => "create")
    end

    it "should map GET /apps/1 to { :controller => 'apps', :action => 'show', :id => '1' }" do
      { :get => "/apps/1" }.should route_to(:controller => 'apps', :action => 'show', :id => '1')
    end

    it "should map GET /apps/1/edit to { :controller => 'apps', :action => 'edit', :id => 1 }" do
      { :get => "/apps/1/edit" }.should route_to(:controller => 'apps', :action => 'edit', :id => '1')
    end

    it "should map PUT /apps/1 to { :controller => 'apps', :action => 'update', :id => '1' }" do
      { :put => "/apps/1" }.should route_to(:controller => 'apps', :action => 'update', :id => '1')
    end

    it "should map DELET /apps/1 to { :controller => 'apps', :action => 'destroy', :id => 1}" do
      { :delete => "/apps/1" }.should route_to(:controller => 'apps', :action => 'destroy', :id => '1')
    end
    
    it "should map GET /apps/1/delete to { :controller => 'apps', :action => 'delete', :id => '1' }" do
      { :get => "/apps/1/delete" }.should route_to(:controller => 'apps', :action => 'delete', :id => '1' )
    end
  end
end

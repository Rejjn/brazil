require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DbInstancesController do
  describe "named route generation" do
    it "should map 'db_instances_path' to /db_instances" do
      {:get => db_instances_path}.should == {:get => '/db_instances'}
    end
    
    it "should map 'new_db_instance_path' to /db_instances/new" do
      {:get => new_db_instance_path}.should == {:get => '/db_instances/new'}
    end

    it "should map 'db_instance_path(:id => 1)' to /db_instances/1" do
      {:get => db_instance_path(1)}.should == {:get => '/db_instances/1'}
    end
    
    it "should map 'edit_db_instance_path(:id => 1)' to /db_instances/1/edit" do
      {:get => edit_db_instance_path(1)}.should == {:get => '/db_instances/1/edit'}
    end
    
    it "should map 'delete_db_instance_path(:id => 1)' to /db_instances/1/delete" do
      {:get => delete_db_instance_path(1)}.should == {:get => '/db_instances/1/delete'}
    end

  end

  describe "route recognition" do
    it "should map GET '/db_instances' to { :controller => 'db_instances', :action => 'index' }" do
      { :get => "/db_instances" }.should route_to(:controller => "db_instances", :action => "index")      
    end

    it "should map GET /db_instances/new to { :controller => 'db_instances', :action => 'new' }" do
      { :get => "/db_instances/new" }.should route_to(:controller => "db_instances", :action => "new")
    end

    it "should map POST /db_instances to { :controller => 'db_instances', :action => 'create' }" do
      { :post => "/db_instances" }.should route_to(:controller => "db_instances", :action => "create")
    end

    it "should map GET /db_instances/1 to { :controller => 'db_instances', :action => 'show', :id => 1 }" do
      { :get => "/db_instances/1" }.should route_to(:controller => 'db_instances', :action => 'show', :id => '1')
    end

    it "should map GET /db_instances/1/edit to { :controller => 'db_instances', :action => 'edit', :id => 1 }" do
      { :get => "/db_instances/1/edit" }.should route_to(:controller => 'db_instances', :action => 'edit', :id => '1')
    end

    it "should map PUT /db_instances/1 to { :controller => 'db_instances', :action => 'update', :id => 1 }" do
      { :put => "/db_instances/1" }.should route_to(:controller => 'db_instances', :action => 'update', :id => '1')
    end

    it "should map DELET /db_instances/1 to { :controller => 'db_instances', :action => 'destroy', :id => 1}" do
      { :delete => "/db_instances/1" }.should route_to(:controller => 'db_instances', :action => 'destroy', :id => '1')
    end
    
    it "should map GET /db_instances/1/delete to { :controller => 'db_instances', :action => 'delete', :id => 1 }" do
      { :get => "/db_instances/1/delete" }.should route_to(:controller => 'db_instances', :action => 'delete', :id => '1')
    end
  end
end

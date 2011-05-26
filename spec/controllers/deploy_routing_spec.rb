require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DeployController do
  describe "named route generation" do
    it "should map 'wipe_instance_schema_app_deploy_path(1, 'SCHEMA', 2)' to /deploy/1/SCHEMA/2/wipe" do
      {:post => wipe_instance_schema_app_deploy_path(1, 'SCHEMA', 2)}.should == {:post => '/deploy/1/SCHEMA/2/wipe'}
    end
    
    it "should map 'rollback_instance_schema_app_deploy_path(1, 'SCHEMA', 2)' to /deploy/1/SCHEMA/2/rollback" do
      {:post => rollback_instance_schema_app_deploy_path(1, 'SCHEMA', 2)}.should == {:post => '/deploy/1/SCHEMA/2/rollback'}
    end

    it "should map 'update_instance_schema_app_deploy_path(1, 'SCHEMA', 1)' to /deploy/1/SCHEMA/2/update" do
      {:post => update_instance_schema_app_deploy_path(1, 'SCHEMA', 2)}.should == {:post => '/deploy/1/SCHEMA/2/update'}
    end
    
    it "should map 'credentials_instance_schema_app_deploy_path(1, 'SCHEMA', 2)' to /deploy/1/SCHEMA/2/credentials" do
      {:put => credentials_instance_schema_app_deploy_path(1, 'SCHEMA', 2)}.should == {:put => '/deploy/1/SCHEMA/2/credentials'}
    end
    
    it "should map 'instance_schema_app_deploy_path' to /deploy/1/SCHEMA/2" do
      {:get => instance_schema_app_deploy_path(1, 'SCHEMA', 2)}.should == {:get => '/deploy/1/SCHEMA/2'}
    end
    
    it "should map 'schema_app_deploy_path' to /deploy/1/SCHEMA" do
      {:get => schema_app_deploy_path(1, 'SCHEMA')}.should == {:get => '/deploy/1/SCHEMA'}
    end    

    it "should map 'app_deploy_path(1)' to /deploy/1" do
      {:get => app_deploy_path(1)}.should == {:get => '/deploy/1'}
    end  
    
    it "should map 'deploy_path' to /deploy" do
      {:get => deploy_path}.should == {:get => '/deploy'}
    end
  end
  
  describe "route recognition" do
    
    it "should map POST /deploy/1/SCHEMA/2/wipe to { :controller => 'deploy', :action => 'wipe', :app => '1', :schema => 'SCHEMA', :db_instance => '2' } to " do
      {:post => '/deploy/1/SCHEMA/2/wipe'}.
        should route_to(:controller => 'deploy', :action => 'wipe', :app => '1', :schema => 'SCHEMA', :db_instance => '2')
    end
    
    it "should map POST /deploy/1/SCHEMA/2/rollback to { :controller => 'deploy', :action => 'rollback', :app => '1', :schema => 'SCHEMA', :db_instance => '2' } to " do
      {:post => '/deploy/1/SCHEMA/2/rollback'}.
        should route_to(:controller => 'deploy', :action => 'rollback', :app => '1', :schema => 'SCHEMA', :db_instance => '2')
    end

    it "should map POST /deploy/1/SCHEMA/2/update to { :controller => 'deploy', :action => 'update', :app => '1', :schema => 'SCHEMA', :db_instance => '2' } to " do
      {:post => '/deploy/1/SCHEMA/2/update'}.
        should route_to(:controller => 'deploy', :action => 'update', :app => '1', :schema => 'SCHEMA', :db_instance => '2')
    end
    
    it "should map POST /deploy/1/SCHEMA/2/credentials to { :controller => 'deploy', :action => 'wipe_credentials', :app => '1', :schema => 'SCHEMA', :db_instance => '2' } to " do
      {:put => '/deploy/1/SCHEMA/2/credentials'}.
        should route_to(:controller => 'deploy', :action => 'wipe_credentials', :app => '1', :schema => 'SCHEMA', :db_instance => '2')
    end

    it "should map POST /deploy/1/SCHEMA/2 to { :controller => 'deploy', :action => 'show_instance', :app => '1', :schema => 'SCHEMA', :db_instance => '2' } to " do
      {:put => '/deploy/1/SCHEMA/2'}.
        should route_to(:controller => "deploy", :action => "show_instance", :app => '1', :schema => 'SCHEMA', :db_instance => '2')
    end

    it "should map POST /deploy/1/SCHEMA to { :controller => 'deploy', :action => 'show_schema', :app => '1', :schema => 'SCHEMA', :db_instance => '2' } to " do
      {:put => '/deploy/1/SCHEMA'}.
        should route_to(:controller => "deploy", :action => "show_schema", :app => '1', :schema => 'SCHEMA')
    end

    it "should map POST /deploy/1 to { :controller => 'deploy', :action => 'show_app', :app => '1' } to " do
      {:put => '/deploy/1'}.
        should route_to(:controller => 'deploy', :action => 'show_app', :app => '1')
    end

    it "should map POST /deploy to { :controller => 'deploy', :action => 'index'} to " do
      {:put => '/deploy'}.
        should route_to(:controller => "deploy", :action => "index")
    end

  end
end

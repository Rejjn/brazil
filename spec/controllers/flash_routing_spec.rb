require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlashController do
  describe "route recognition" do
    it "should map GET /flash/notice to { :controller => 'flash', :action => 'notice' }" do
      { :get => "/flash/notice" }.should route_to(:controller => 'flash', :action => 'notice')      
    end

    it "should map GET /flash/error to { :controller => 'flash', :action => 'error' }" do
      { :get => "/flash/error" }.should route_to(:controller => 'flash', :action => 'error')      
    end
    
    it "should map GET /flash/executed_sql to { :controller => 'flash', :action => 'executed_sql' }" do
      { :get => "/flash/executed_sql" }.should route_to(:controller => 'flash', :action => 'executed_sql')      
    end
    
  end
end

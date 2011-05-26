require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlashController do
  describe "route recognition" do
    it "should map GET /repo_browser to { :controller => 'repo_browser', :action => 'index' }" do
      { :get => "/repo_browser" }.should route_to(:controller => 'repo_browser', :action => 'index')      
    end
  end
end

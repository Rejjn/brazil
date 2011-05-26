require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DbInstancesController do
  
  before(:each) do
    @db_instance = mock_model(DbInstance)
    DbInstance.stub!(:find).and_return([@db_instance])
  end  
  
  AccessControlHelper.real_actions(DbInstancesController).each do |action|
    describe "requesting #{action} on DbInstancesController" do
      it "should result in http 401 if basic auth is empty" do
        AccessControlHelper.http_method(action, self).call action.to_sym, :id => '1'
        response.code.should eq("401")
      end
    end
  end
end
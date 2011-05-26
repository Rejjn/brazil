require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DeployController do
  AccessControlHelper.real_actions(DeployController).each do |action|
    describe "requesting #{action} on DeployController" do
      it "should result in http 401 if basic auth is empty" do
        AccessControlHelper.http_method(action, self).call action.to_sym
        response.code.should eq("401")
      end
    end
  end
end
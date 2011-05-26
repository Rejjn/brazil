require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActivitiesController do
  
  before(:each) do
    @app = mock_model(App, :to_param => "1")

    @activity = mock_model(Activity, :to_param => "1")

    @activities = mock(Array)
    @activities.stub!(:find).with("2").and_return(@activity)
    @app.stub!(:activities).and_return(@activities)

    App.stub!(:find).with("1").and_return(@app)
  end
  
  
  AccessControlHelper.real_actions(ActivitiesController).each do |action|
    describe "requesting #{action} on ActivitiesController" do
      it "should result in http 401 if basic auth is empty" do
        AccessControlHelper.http_method(action, self).call action.to_sym, :app_id => '1', :id => '2'
        response.code.should eq("401")
      end
    end
  end
end
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChangesController do
  
  before(:each) do
    @app = mock_model(App, :to_param => "1")
    App.stub!(:find).with("1").and_return(@app)

    @activity = mock_model(Activity, :to_param => "2")
    @activity.stub!(:app).and_return(@app)

    @activities = mock(Array)
    @activities.stub!(:find).and_return(@activity)
    @app.stub!(:activities).and_return(@activities)

    change = mock_model('Change')
    @changes = mock(Array)
    @changes.stub!(:find).and_return(change)
    @activity.stub!(:changes).and_return(@changes)

    Activity.stub!(:find).with("2").and_return(@activity)
  end  
  
  AccessControlHelper.real_actions(ChangesController).each do |action|
    describe "requesting #{action} on ChangesController" do
      it "should result in http 401 if basic auth is empty" do
        AccessControlHelper.http_method(action, self).call action.to_sym, :app_id => '1', :activity_id => '2', :id => '3'
        response.code.should eq("401")
      end
    end
  end
end
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do
  
  before(:each) do
    @app = mock_model(App, :to_param => "1")

    @activity = mock_model(Activity, :to_param => "1")

    @activities = mock(Array)
    @activities.stub!(:find).with("1").and_return(@activity)
    @app.stub!(:activities).and_return(@activities)

    App.stub!(:find).with("1").and_return(@app)
  end
  
  describe "requesting GET /apps/:app_id/activities" do

    it "should result in http 401 if basic auth is empty" do
      get :index, :app_id => '1'
      response.code.should eq("401")
    end
    
    it "should result in http 401 if credentials are invalid" do
      @request.env["HTTP_AUTHORIZATION"] = BasicAuthHelper.auth_string("thisuser:doesnotexist")
      get :index, :app_id => '1'
      response.code.should eq("401")
      
      @request.env["HTTP_AUTHORIZATION"] = BasicAuthHelper.auth_string("ldap_svnbuildserver:invalidpassword")
      get :index, :app_id => '1'
      response.code.should eq("401")
    end
  end
  
  describe "requesting GET /apps/:app_id/activities/1" do
    it "should result in http 401 if basic auth is empty" do
      get :new, :app_id => '1', :id => '1'
      response.code.should eq("401")
    end
  end
  
  describe "requesting GET /apps/:app_id/activities/new" do
    it "should result in http 401 if basic auth is empty" do
      get :new, :app_id => '1'
      response.code.should eq("401")
    end
  end
  
  describe "requesting GET /apps/:app_id/activities/1/edit" do
    it "should result in http 401 if basic auth is empty" do
      get :edit, :app_id => '1', :id => '1'
      response.code.should eq("401")
    end
  end
  
  describe "requesting GET /apps/:app_id/activities/1/delete" do
    it "should result in http 401 if basic auth is empty" do
      get :delete, :app_id => '1', :id => '1'
      response.code.should eq("401")
    end
  end

  describe "doing DELETE /apps/:app_id/activities/1" do
    it "should result in http 401 if basic auth is empty" do
      delete :destroy, :app_id => '1', :id => '1'
      response.code.should eq("401")
    end
  end

  describe "doing POST /apps/:app_id/activities/1" do
    it "should result in http 401 if basic auth is empty" do
      post :delete, :app_id => '1', :id => '1'
      response.code.should eq("401")
    end
  end
end
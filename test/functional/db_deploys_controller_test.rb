require 'test_helper'

class DbDeploysControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:db_deploys)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create db_deploy" do
    assert_difference('DbDeploy.count') do
      post :create, :db_deploy => { }
    end

    assert_redirected_to db_deploy_path(assigns(:db_deploy))
  end

  test "should show db_deploy" do
    get :show, :id => db_deploys(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => db_deploys(:one).to_param
    assert_response :success
  end

  test "should update db_deploy" do
    put :update, :id => db_deploys(:one).to_param, :db_deploy => { }
    assert_redirected_to db_deploy_path(assigns(:db_deploy))
  end

  test "should destroy db_deploy" do
    assert_difference('DbDeploy.count', -1) do
      delete :destroy, :id => db_deploys(:one).to_param
    end

    assert_redirected_to db_deploys_path
  end
end

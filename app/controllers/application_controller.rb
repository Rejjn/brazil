class ApplicationController < ActionController::Base
  
  include UserInfo
  
  protect_from_forgery
  
  filter_parameter_logging :password, :db_password

  add_crumb 'Home', '/'

  before_filter :add_controller_crumbs, :except => :destroy
  before_filter(:only => :new) { |controller| controller.add_crumb('New') }
  before_filter(:only => :edit) { |controller| controller.add_crumb('Edit') }

  before_filter :authenticate
  before_filter :set_user

  private

  def add_app_controller_crumbs(app_model)
    add_crumb 'Apps', apps_path
    add_crumb app_model.to_s, app_path(app_model)
  end

  def add_activities_controller_crumbs(app_model, activity_model=nil)
    add_crumb 'Activities', app_activities_path(app_model)

    if activity_model
      add_crumb activity_model.to_s, app_activity_path(app_model, activity_model)
    end
  end
  
  def authenticate
    
    return true if session[:user]
    
    authenticate_or_request_with_http_basic('Brazil Login (Ongame AD)') do |username, password|
      
    ldap = Net::LDAP.new(
      :host => ::AppConfig.ad_host, 
      :port => ::AppConfig.ad_port
    )
    ldap.authenticate "#{username}@#{::AppConfig.ad_domain}", password
      
      if ldap.bind
        session[:user] = username
        
        if ::AppConfig.admins.include? username
          session[:admin] = true
        else
          session[:admin] = false
        end
        
        true
      else
        session[:user] = nil
        session[:admin] = false
        false
      end
    end
  end
  
  # Sets the current user into a named Thread location so that it can be accessed
  # by models and observers
  def set_user
    UserInfo.current_user = session[:user]
  end
    
  
end

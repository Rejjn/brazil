class SqlController < AbstractController::Base
  include AbstractController::Rendering
  #include AbstractController::Layouts
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  #include ActionController::UrlWriter

  # Uncomment if you want to use helpers defined in ApplicationHelper in your views
  helper SqlHelper

  # Make sure your controller can find views
  self.view_paths = "app/views/sql"

  def update_sql version
    render_to_string :template => "update_sql", :locals => {:version => version}
  end
  
  def rollback_sql version
    render_to_string :template => "rollback_sql", :locals => {:version => version}
  end

end
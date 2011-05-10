require 'httpclient'

class RepoBrowserController < ApplicationController
  layout false
  
  skip_filter :add_controller_crumbs
  
  def index
    params[:url] = '' unless params[:url]
    
    @repo_page = ""
    clnt = HTTPClient.new
    begin
      @repo_page = clnt.get_content(::AppConfig.vc_uri + "/" + params[:url])
    rescue HTTPClient::BadResponseError
      @repo_page = clnt.get_content(::AppConfig.vc_uri)
    end
  end

end

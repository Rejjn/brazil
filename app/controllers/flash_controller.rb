
require 'brazil/sessionsql_storage'

class FlashController < ApplicationController
  layout false
  
  skip_filter :add_controller_crumbs

  def notice
  end

  def executed_sql
    @sql = Brazil::SessionSQLStorage.retrieve_sql(session[:sql_store])
  end
end
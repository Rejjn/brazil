
require 'brazil/sessionsql_storage'

class FlashController < ApplicationController
  layout false
  
  skip_filter :add_controller_crumbs
  after_filter :discard_flash
  
  def notice
  end

  def error
  end

  def executed_sql
    @sql = Brazil::SessionSQLStorage.retrieve_sql(session[:sql_store])
  end
  
  private 
  
  def discard_flash
    flash.discard
  end
end
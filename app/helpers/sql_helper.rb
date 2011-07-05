module SqlHelper

  def sql_escape(object)
    escaped_object = DBI::TypeUtil.convert(nil, object)
    if escaped_object
      escaped_object
    else
      "NULL"
    end
  end
   
end
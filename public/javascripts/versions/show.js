$(document).ready(function() {

  brazil.on_load.general();

  jQuery.each(jQuery('.attribute_warning'), function(index, value) {
    //brazil.warning.show(jQuery(value))
  });

/*  
  jQuery.each(jQuery('.sql_tested_oki'), function(index, value) {
    brazil.element.show({ 
      link_html: '<a href="#">Show Form</a>', 
      button_html: '<span style="float: right;"></span>', 
      to_show: value, 
      button_container: jQuery(value).parent(), 
    });
  });
  
  brazil.element.show({ 
    link_html: '<a href="#">Show Preparation</a>', 
    button_html: '<span style="float: right;"></span>', 
    to_show: jQuery('.preparation'), 
    button_container: jQuery('.preparation').parent(), 
  });
*/
  
});

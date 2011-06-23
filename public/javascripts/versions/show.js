$(document).ready(function() {

  brazil.on_load.general();

  jQuery.each(jQuery('.attribute_warning'), function(index, value) {
    //brazil.warning.show(jQuery(value))
  });
  
  brazil.info.setup_toggle({ 
    container: jQuery('.sql_box').parent(), 
    affected_element: '.sql_box', 
    show_caption: 'Show', 
    hide_caption: 'Hide'
  });
  
  brazil.info.setup_toggle({ 
    container: jQuery('.preparation').parent(), 
    affected_element: '.preparation', 
    show_caption: 'Show', 
    hide_caption: 'Hide'
  });
  
});

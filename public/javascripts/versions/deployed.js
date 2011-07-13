$(document).ready(function() {
  brazil.on_load.general();
  
  brazil.info.setup_toggle({
    container: '.executed_sql_box',
    affected_element: '.executed_sql',
    show_caption: 'Show SQL',
    hide_caption: 'Hide SQL'
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
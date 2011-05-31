var deploy_forms = function(){
  brazil.form.existing({
    form_container: '#deploy_wipe_fieldset',
    response_container: '#deployment',
    success: function(){
      brazil.flash.notice('#deploy_notice');
    },
    error: function(){
      brazil.flash.error('#deploy_error');
    },
    done: function(){
      brazil.manipulate.syntax_highlight();
      deploy_forms();
    },
  });
  
  brazil.form.existing({
    form_container: '#deploy_rollback_fieldset',
    response_container: '#deployment',
    success: function(){
      brazil.flash.notice('#deploy_notice');
      brazil.info.setup_toggle({
        container: '.executed_sql_box', 
        affected_element: '.executed_sql', 
        show_caption: 'Show SQL', 
        hide_caption: 'Hide SQL'
      });
    },
    error: function(){
      brazil.flash.error('#deploy_error');
    },
    done: function(){
      brazil.manipulate.syntax_highlight();
      deploy_forms();
    },
  });
  
  brazil.form.existing({
    form_container: '#deploy_update_fieldset',
    response_container: '#deployment',
    success: function(){
      brazil.flash.notice('#deploy_notice');
      brazil.flash.error('#deploy_error');
      brazil.info.setup_toggle({
        container: '.executed_sql_box', 
        affected_element: '.executed_sql', 
        show_caption: 'Show SQL', 
        hide_caption: 'Hide SQL'
      });
    },
    error: function(){
      brazil.flash.error('#deploy_error');
    },
    done: function(){
      brazil.manipulate.syntax_highlight();
      deploy_forms();
    },
  });
  
  brazil.info.setup_toggle({
    container: '#deployed_versions_box', 
    affected_element: '#all_deployed_versions', 
    show_caption: 'Show Versions', 
    hide_caption: 'Hide Versions'
  });  
  
  
}

$(document).ready(function() {

  jQuery('#app').live('change', function() {
    if (jQuery(this).val().substr(0, 2) != '--') {
      window.location = '/deploy/' + (jQuery(this).val());  
    }
  });
  
  jQuery('#schema').live('change', function() {
    if (jQuery(this).val().substr(0, 2) != '--') {
      var location = new String(window.location);
      var location_parts = location.split('/');
      window.location = '/' + location_parts[3] + "/" + location_parts[4] + '/' + jQuery(this).val();
    }
  });
  
  jQuery('#db_instance').live('change', function() {
    if (jQuery(this).val().substr(0, 2) != '--') {
      var location = new String(window.location);
      var location_parts = location.split('/');
      window.location = '/' + location_parts[3] + "/" + location_parts[4] + '/' + location_parts[5] + '/' + jQuery(this).val();
    }
  });
  
  deploy_forms();
});
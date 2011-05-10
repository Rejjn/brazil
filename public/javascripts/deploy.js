var deploy_forms = function(){
  brazil.form.existing({
    form_container: '#deploy_wipe_fieldset',
    response_container: '#deployment',
    success: function(){
      brazil.flash.notice('#deploy_notice');
      brazil.sql.show();
    },
    error: function(){
      brazil.flash.error('#deploy_error');
      brazil.sql.show();
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
      brazil.sql.show();
    },
    error: function(){
      brazil.flash.error('#deploy_error');
      brazil.sql.show();
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
      brazil.sql.show();
    },
    error: function(){
      brazil.flash.error('#deploy_error');
      brazil.sql.show();
    },
    done: function(){
      brazil.manipulate.syntax_highlight();
      deploy_forms();
    },
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
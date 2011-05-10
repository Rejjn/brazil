$(document).ready(function() {
  brazil.manipulate.syntax_highlight();
  brazil.move.scrollable('#activity_forms');

  jQuery.each(jQuery('.attribute_warning'), function(index, value) {
    brazil.warning.show(jQuery(value))
  });
  
  brazil.flash.fadeout('#notice', 3000);
  
  brazil.element.show({ 
    link_html: '<a href="#">Show SQL</a>', 
    button_html: '<span style="float: right;"></span>', 
    to_show: jQuery('#deployed_sql'), 
    button_container: jQuery('#deployed_sql').parent(), 
  });  

  // Edit Activity
  brazil.form.inline({
    show_form: '#activity_edit_button',
    form_container: '#activity',
    success: function() {
      brazil.flash.notice();
    }
  });

  // New Change
  brazil.form.existing({
    form_container: '#new_change_fieldset',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice();
      brazil.sql.show();
    },
    error: function() {
      brazil.flash.error();
      brazil.sql.show();
    },
    done: function() {
      brazil.manipulate.syntax_highlight();
    },
  });

  // Edit Change
  brazil.form.insert({
    show_form: '.edit_change_button',
    form_container: '#activity_forms',
    inserted_fieldset: '#edit_change_fieldset',
    response_container: '#changes',
    success: function() {
      brazil.manipulate.syntax_highlight();
      brazil.flash.notice();
    }
  });
  
  // Execute Change
  brazil.request.execute({
    button: '.execute_change_button',
    method: 'GET',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice('#change_notice');
      brazil.sql.show();
    },
    error: function() {
      brazil.flash.error('#change_error');
      brazil.sql.show();
    },
    done: function() {      
      brazil.manipulate.syntax_highlight();
    }
  });
  
  // Execute Activity
  brazil.request.execute({
    button: '.execute_activity_button',
    method: 'GET',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice();
      brazil.sql.show();
    },
    error: function() {
      brazil.flash.error();
      brazil.sql.show();
    },
    done: function() {      
      brazil.manipulate.syntax_highlight();
    }
  });
  
});


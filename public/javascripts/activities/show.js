var change_form = function(){
  // New Change
  brazil.form.existing({
    form_container: '#new_change_fieldset',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice();
      brazil.flash.error();
    },
    error: function() {
      brazil.flash.error();
    },
    done: function() {
      brazil.manipulate.syntax_highlight();
      brazil.info.setup_toggle({
        container: '.executed_sql_box', 
        affected_element: '.executed_sql', 
        show_caption: 'Show SQL', 
        hide_caption: 'Hide SQL'
      });
      brazil.info.setup_close('#executed_sql_box');
      change_form();
    },
  });

  // Edit Change
  brazil.form.insert({
    show_form: '.edit_change_button',
    form_container: '#activity_forms',
    inserted_fieldset: '#edit_change_fieldset',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice();
      brazil.flash.error();
    },
    error: function() {
      brazil.flash.error();
    },
    done: function() {
      brazil.manipulate.syntax_highlight();
      brazil.info.setup_toggle({
        container: '.executed_sql_box', 
        affected_element: '.executed_sql', 
        show_caption: 'Show SQL', 
        hide_caption: 'Hide SQL'
      });
      brazil.info.setup_close('#executed_sql_box');
      change_form();
    },
  });
  
  // Execute Change
  brazil.request.execute({
    button: '.execute_change_button',
    method: 'POST',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice('#change_notice');
      brazil.flash.error('#change_error');
    },
    error: function() {
      brazil.flash.error('#change_error');
    },
    done: function() {      
      brazil.manipulate.syntax_highlight();
      brazil.info.setup_toggle({
        container: '.executed_sql_box', 
        affected_element: '.executed_sql', 
        show_caption: 'Show SQL', 
        hide_caption: 'Hide SQL'
      });
      brazil.info.setup_close('#executed_sql_box');
      change_form();
    }
  });  
}

$(document).ready(function() {
  brazil.on_load.general();
  brazil.move.scrollable("#activity_forms");

  jQuery.each(jQuery('.attribute_warning'), function(index, value) {
    // brazil.warning.show(jQuery(value))
  });
  
  change_form();
  
  // Edit Activity
  brazil.form.inline({
    show_form: '#activity_edit_button',
    form_container: '#activity',
    success: function() {
      brazil.flash.notice();
    }
  });
  
  // Execute Activity
  brazil.request.execute({
    button: '.execute_activity_button',
    method: 'POST',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice();
      brazil.flash.error();
    },
    error: function() {
      brazil.flash.error();
    },
    done: function() {      
      brazil.manipulate.syntax_highlight();
      brazil.info.setup_toggle({
        container: '.executed_sql_box', 
        affected_element: '.executed_sql', 
        show_caption: 'Show SQL', 
        hide_caption: 'Hide SQL'
      });
      brazil.info.setup_close('#executed_sql_box');
      change_form();
    }
  });

  // Reset Activity
  brazil.request.execute({
    button: '.reset_activity_button',
    method: 'POST',
    response_container: '#changes',
    success: function() {
      brazil.flash.notice();
      brazil.flash.error();
    },
    error: function() {
      brazil.flash.error();
    },
    done: function() {
      brazil.manipulate.syntax_highlight();
      change_form();
    }
  });

});


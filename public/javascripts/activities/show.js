$(document).ready(function() {
  brazil.manipulate.syntax_highlight();
  brazil.move.scrollable('#activity_forms');

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
      brazil.manipulate.syntax_highlight();
      brazil.flash.notice();
      brazil.sql.show();
    },
    error: function() {
      brazil.sql.show();
    }
  });

  // Suggest Change
  brazil.form.insert({
    show_form: '#suggest_change_button',
    form_container: '#activity_forms',
    inserted_fieldset: '#suggest_change_fieldset',
    response_container: '#changes',
    success: function() {
      brazil.manipulate.syntax_highlight();
      brazil.flash.notice();
    }
  });

  // Edit / Approve Change
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
});

function sql_show_controls(){
  if ($("#deployed_sql").is(":hidden")) {
    $("#deployed_sql").slideDown("slow");
    $("#sql_show_controls").html("Hide SQL");
  }
  else {
    $("#deployed_sql").slideUp();
    $("#sql_show_controls").html("Show SQL");
  }
}


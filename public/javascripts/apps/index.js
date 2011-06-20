$(document).ready(function() {
  brazil.on_load.general();

  // Edit App name
  brazil.form.inline({
    show_form: '.edit_app_button',
    form_container: '.head'
  });

  // Add Activity
  brazil.form.insert_only({
    show_form: '.add_activities_button',
    form_container: '#app_forms',
    inserted_fieldset: '#new_activity_fieldset'
  });
});
$(document).ready(function() {
  // brazil.move.scrollable('#activity_forms');
  
  brazil.flash.fadeout('#notice', 3000);
  
  // Edit App name
  brazil.form.inline({
    show_form: '.edit_app_button',
    form_container: '.head'
  });
});
$(document).ready(function() {
  brazil.manipulate.syntax_highlight();
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

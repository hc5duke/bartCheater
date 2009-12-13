document.observe('dom:loaded', function(){
  $('refresh').onclick = function() {
    location.reload(true);
  };
  var color = $('color');
  if (color) {
    color.onclick = function() {
      location.search = "?color=true";
    }
  }

  var noColor = $('no_color');
  if (noColor) {
    noColor.onclick = function() {
      location.search = "";
    }
  }
});

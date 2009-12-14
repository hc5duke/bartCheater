document.observe('dom:loaded', function(){
  var refresh = $('refresh');
  var color = $('color');
  var noColor = $('no_color');

  refresh.onclick = function() { location.reload(true); };
  if (color) { color.onclick = function() { location.search = "?color=true"; } }
  if (noColor) { noColor.onclick = function() { location.search = ""; } }

  ['home', 'west'].each(function(dir) {
    trains.findAll(function(t){
      return t.direction == dir;
    }).each(function(train){
      if (!train.seen_at["_EMBR"]) return;
      var div = ["<div class=\"train ", (noColor ? train.destination : ''), "\">", train.seen_at["_EMBR"], "</div>"]
      $('trains_'+dir).insert(div.join(''));
    });
  });

  // $('home').select('div.train').each(function(train){
  //   train.onclick = function() {
  //     console.log('click !')
  //   }
  // });
  // -[:home, :west].each do |dir|
  //   %div{:id => dir.to_s}
  //     %h1
  //       =dir.to_s.titlize
  //     -@bart.trains[dir].each do |train|
  //       -next if train.offset_eta < 0
  //       %div{:class => "train #{train.destination.class_name if using_color}"}
  //         =train.offset_eta
  //     %div{:class => "br"}
});

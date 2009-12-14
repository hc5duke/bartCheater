var Bart = Class.create({
  initialize: function(options) {
    this._trains = options.trains;
    this._lastSelected = null;
    document.observe('dom:loaded', this.setupHtml.bind(this));
    document.observe('dom:loaded', this.observeClicks.bind(this));
  },

  setupHtml: function() {
    var refresh = $('refresh');
    var color = $('color');
    var noColor = $('no_color');

    refresh.onclick = function() { location.reload(true); };
    if (color) { color.onclick = function() { location.search = "?color=true"; } }
    if (noColor) { noColor.onclick = function() { location.search = ""; } }

    ['home', 'west'].each(function(dir) {
      var div = $('trains_'+dir);
      this._trains.findAll(function(t){
        return t.direction == dir;
      }).each(function(train){
        if (!train.seen_at["_EMBR"]) return;
        var trainDiv = ["<div class=\"train ", (noColor ? train.destination : ''), "\">", train.seen_at["_EMBR"], "</div>"]
        div.insert(trainDiv.join(''));
      });
    }, this);
  },

  observeClicks: function() {
    $$('div.train').each(function(train){
      train.onclick = this.trainClickEvent.bind(this);
    }, this);
  },

  trainClickEvent: function(e) {
    var train = e.element();
    if (this._lastSelected) {
      this._lastSelected.removeClassName('selected');
    }
    train.addClassName('selected')
    this._lastSelected = train;
  }
});

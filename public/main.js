if (!typeof(console)) {
  var noFunk = function(){};
  console = {
    debug: noFunk,
    err: noFunk,
    info: noFunk,
    log: noFunk,
    warn: noFunk,
    trace: noFunk
  };
}
var debug = true;
var LOG = function(o) {
  if (debug) console.log(o);
}
var Bart = Class.create({
  initialize: function(options) {
    this._trains = options.trains;
    this._station = options.station;
    this._directedTrains = {};
    this._splitTrains();
    this._lastSelected = null;
    document.observe('dom:loaded', this.setupHtml.bind(this));
    document.observe('dom:loaded', this.observeClicks.bind(this));
  },

  _splitTrains: function() {
    this._dirs.each(function(dir) {
      this._directedTrains[dir] = this._trains.findAll(function(t){
        return t.direction == dir;
      });
    }, this);
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
      var here = '_' + this._station;
      this._directedTrains[dir].each(function(train){
        if (train.seen_at[here] == undefined) {
          LOG(['not logged => ', train.seen_at])
          return;
        }
        var className = 'box train ' + (noColor ? train.destination : '');
        var trainDiv = new Element('div', {'class': className}).update(train.seen_at["_EMBR"]);
        train.div = trainDiv;
        trainDiv.store('train', train);
        div.insert(trainDiv);
      }, this);
      div.insert('<div class="br">&nbsp;</div>');
    }, this);
  },

  observeClicks: function() {
    $$('div.train').each(function(train){
      train.onclick = this.trainClickEvent.bind(this);
    }, this);
  },

  trainClickEvent: function(e) {
    var trainDiv = e.element();
    var trainData = trainDiv.retrieve('train');
    if (this._lastSelected) {
      this._lastSelected.removeClassName('selected');
    }
    ['MONT', 'POWL', 'CIVC', '16TH'].each(function(c){
      $$('.reachable-'+c).invoke('removeClassName', 'reachable-'+c);
    });
    trainDiv.addClassName('selected')
    if (trainData.direction == 'home') {
      if (trainData.seen_at['_CIVC']) {
        this._directedTrains.west.each(function(t) {
          if (t.div && t.seen_at['_CIVC'] < trainData.seen_at['_CIVC']) {
            t.div.addClassName('reachable-CIVC')
          }
        });
      }
    }
    this._lastSelected = trainDiv;
  },

  _dirs: ['home', 'west']
});

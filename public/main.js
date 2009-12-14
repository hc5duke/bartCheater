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
var debug = false;
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
    Event.observe(window, 'resize', function() {
      var element = this._lastSelected;
      if (element) {
        var e = { element: function() {return element;} };
        this.trainClickEvent(e);
      }
    }.bind(this));
  },

  _splitTrains: function() {
    this._dirs.each(function(dir) {
      this._directedTrains[dir] = this._trains.findAll(function(t){
        return t.direction == dir;
      });
    }, this);
  },

  setupHtml: function() {
    var refresh = $$('input.refresh');
    var color = $('color');
    var noColor = $('no_color');

    refresh.each(function(r){
      r.onclick = function() { location.reload(true); };
    })
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
    var boxWidth = 50;
    var trainDiv = e.element();
    var trainData = trainDiv.retrieve('train');
    LOG(trainData)
    var stations = ['_MONT', '_POWL', '_CIVC', '_16TH'].reverse();
    if (this._lastSelected) {
      this._lastSelected.removeClassName('selected');
    }
    stations.each(function(c){
      $$('.reachable'+c).invoke('removeClassName', 'reachable'+c);
    });
    $$('.not_reachable').invoke('removeClassName', 'not_reachable');
    trainDiv.addClassName('selected');
    if (trainData.direction == 'home') {
      $$('#trains_west div.box').invoke('addClassName', 'not_reachable');
      stations.each(function(c, i){
        var maxOffset = {left: 0};
        if (trainData.seen_at[c]) {
          this._directedTrains.west.each(function(t) {
            if (t.div && t.seen_at[c] < trainData.seen_at[c]) {
              t.div.removeClassName('not_reachable');
              t.div.addClassName('reachable'+c);
              var offset = t.div.positionedOffset();
              maxOffset = offset;
            }
          });
        }
        var div = $('box' + c.toLowerCase()), top, left;
        if (maxOffset.left) {
          top = maxOffset.top + 2 + 8*i;
          left = (maxOffset.left + boxWidth - div.offsetWidth-2);
        } else {
          left = -20;
        }
        div.setStyle({ top: top + 'px', left: left + 'px' });
      }, this);
    }
    this._lastSelected = trainDiv;
  },

  _dirs: ['home', 'west']
});

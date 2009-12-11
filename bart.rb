require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'hpricot'
require 'ruby-debug'

#
# routes/actions
#
get '/main.css' do
  require 'sass'
  sass :main
end

get '/' do
  require 'haml'
  @bart = Bart.new true
  haml :index
end

#
# models
#
class Bart
  attr_accessor :trains, :stations
  @@stations_to_watch = ['EMBR', 'MONT', 'POWL', 'CIVC']

  def initialize static=false
    xml = static ? "sample/1807.xml" : "http://www.bart.gov/dev/eta/bart_eta.xml"
    @stations = parse_stations(Hpricot(open(xml))/"station")
  end

  def parse_stations doc
    @@stations_to_watch.map do |st|
      Station.new(doc.find{|x| (x/"abbr").inner_html == st})
    end
  end
end

class Station
  attr_accessor :abbr, :lines
  alias :name :abbr
  def initialize doc
    @abbr = (doc/"abbr").inner_html
    @lines = (doc/"eta").map{|e| Line.new e}.sort
  end

  def line_to_s
    [
      lines.select{|e| e.going_home?}.map{|e| "#{e.destination} #{e.estimates.join(':')}"}.join("<br/>\n"),
      lines.select{|e| e.westbound?}.map{|e| "#{e.destination} #{e.estimates.join(':')}"}.join("<br/>\n"),
      lines.select{|e| e.eastbound? && !e.going_home?}.map{|e| "#{e.destination} #{e.estimates.join(':')}"}.join("<br/>\n")
    ].join "<br/><br/>\n"
    # lines.map{|e| "#{e.destination} #{e.estimates.join(':')}"}.join("<br/>\n")
  end
end

class Line
  attr_accessor :destination, :estimates
  def initialize doc
    @destination = (doc/"destination").inner_html
    @estimates = (doc/"estimate").inner_html.gsub(/\s|min/,'').split(/,/).map(&:to_i)
  end

  def westbound?
    !!@destination.match(/daly|millbrae|airport|24th/i)
  end
  def eastbound?; !westbound? end

  def going_home?
    !!@destination.match(/dubl/i)
  end

  def sort_value; going_home? ? -1 : (westbound? ? 0 : 1) end
  def <=> obj
    sort_value <=> obj.sort_value
  end
end

class Train
  attr_accessor :destination, :nearby_stations
  def initialize options
    @destination = options.destination
    @stations = options.station
  end
end

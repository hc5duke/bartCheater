require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'hpricot'

#
# routes/actions
#
get '/main.css' do
  require 'sass'
  sass :main
end

get '/at' do
  Bart.new true
end

get '/' do
  require 'haml'
  name = params['station'] || 'EMBR'
  station = create_station name
  "<h1>#{station.name}</h1> #{station.line_to_s}}"
  haml :index
end

# get '/' do
#   haml :index
#   doc = Hpricot(open("sample/1807.xml"))
#   _puts = "<br/>EMBR<br/>"
#   s = find_station "EMBR"
#   abbr = (s/"abbr").inner_html
#   opposite = (s/"eta").select{|x| (opp_dir? (x/"destination").to_s)}
#   if abbr=='DUBL'
#     opposite.each do |e|
#       _puts += print_est e, true
#     end
#   else
#     times = find_and_sort_opp_times opposite
#     _puts += times.map{|t| t.to_i==0?'Arr':"#{t}m"}.join(', ')
#   end
#   (s/"eta").reject{|x| (opp_dir? (x/"destination").to_s)}.each do |e|
#     _puts += print_est e, (abbr=='DUBL')
#   end
#   _puts
# end

def stations
  @stations ||= Hpricot(open("sample/1807.xml"))/"station"
end

def create_station station
  Station.new stations.find{|x| (x/"abbr").inner_html == station}
end

# def find_station station
#   stations.find{|x| (x/"abbr").inner_html == station}
# end

def opp_dir? station
  return station.match(/daly|millbrae|airport|24th/i)
end

def print_est e, dp
  dest = (e/"destination").to_s
  class_name = (dp || dest.match(/dubl/i)) ? "good" : "ignore"
  class_name = "opposite" if class_name == "ignore" && (opp_dir? dest)
  info = (e/"estimate").to_s
  return "#{dest}: #{info}"
end

def find_and_sort_opp_times opposite
  times = []
  opposite.each do |e|
    times += (e/"estimate").inner_html.gsub("Arrived","0").gsub(/[^\d,]/,'').split(',')
  end
  times.sort{|x,y| x.to_i<=>y.to_i}
end

class Station
  attr_accessor :abbr, :lines
  alias :name :abbr
  def initialize doc
    @abbr = (doc/"abbr").inner_html
    @lines = (doc/"eta").map{|e| eta = Line.new e}.sort
  end
  def line_to_s
    lines.map{|e| e.destination + " " + e.estimate}.join('<br/>')
  end
end

class Line
  attr_accessor :destination, :estimate
  def initialize doc
    @destination = (doc/"destination").inner_html
    @estimate = (doc/"estimate").inner_html
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

class Bart
  attr_accessor :trains, :stations
  def initialize static=false
    xml = static ? "sample/1807.xml" : "http://www.bart.gov/dev/eta/bart_eta.xml"
    @system = Hpricot(open(xml))/"station"
  end

  def parse
    @stations = ''
  end
end
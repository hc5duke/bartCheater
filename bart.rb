require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'hpricot'
require 'ruby-debug'

#
# routes/actions
#
get '/' do
  require 'haml'
  @bart = Bart.new true
  haml :index
end
@@station_names   = ['EMBR', 'MONT', 'POWL', 'CIVC', '16TH']
@@station_offsets = [     0,      2,      3,      5,      8] # time between stations

#
# models
#
class Bart
  attr_accessor :trains, :stations
  def initialize static=false
    xml = static ? "sample/1807.xml" : "http://www.bart.gov/dev/eta/bart_eta.xml"
    @doc = Hpricot(open(xml))/"station"
    @stations = @@station_names.map do |st|
      Station.new(@doc.find{|x| (x/"abbr").inner_html == st})
    end
    get_trains_from stations
  end

  def get_trains_from stations
    @trains = {:home => [], :west => []}
    stations.each do |st|
      @trains.keys.each do |dir|
        relevant_lines = st.lines.select{|line| line.direction == dir}
        relevant_lines.map(&:trains).flatten.each do |train|
          check_new_train @trains[dir], train
        end
        @trains[dir].sort!
      end
    end
  end

  def check_new_train trains, train
    found = trains.find{|t| t.similar? train}
    if !found
      trains << train
    else
      found.seen_at << train.station
    end
  end
end

class Train
  attr_accessor :destination, :eta, :station, :seen_at
  def initialize options
    @destination = options[:destination]
    @eta = options[:eta]
    @station = options[:station]
    @seen_at = [@station]
  end

  def offset_eta
    (@destination.direction == :west) ? eta - @station.offset : eta + @station.offset
  end

  def similar? obj
    (@destination == obj.destination) && (offset_eta - obj.offset_eta).abs < 2
  end

  def <=> obj
    if @destination.direction == obj.destination.direction
      offset_eta <=> obj.offset_eta
    else
      throw Exception.new "directions do not match (#{@destination.direction} != #{obj.destination.direction})"
    end
  end
end

class Station
  attr_accessor :abbr, :lines
  alias :name :abbr
  def initialize doc
    @abbr = (doc/"abbr").inner_html
    @lines = (doc/"eta").map{|e| Line.new(e, self)}.sort
  end

  def offset
    @@station_offsets[@@station_names.index(@abbr)]
  end
end

class Line
  attr_accessor :station, :destination, :trains
  def initialize doc, station
    @station = station
    @destination = Destination.new((doc/"destination").inner_html)
    estimates = (doc/"estimate").inner_html.gsub(/\s|min/,'').split(/,/).map(&:to_i)
    @trains = find_trains estimates
  end

  def find_trains estimates
    estimates.map do |eta|
      Train.new(:destination => @destination, :eta => eta, :station => @station)
    end
  end

  def direction
    @destination.direction
  end

  def value
    direction == :home ? -1 : direction == :west ? 0 :1
  end

  def <=> obj; value <=> obj.value end
end

class Destination
  attr_accessor :name, :direction
  def initialize name
    @name = name
    @direction = name.match(/daly|millbrae|airport|24th/i) ? :west : name.match(/dubl/i) ? :home : :east
  end

  def == obj
    obj.name == name
  end

  def class_name
    name.downcase.gsub(/\s+|\//,'_').gsub(/^([^a-zA-Z])/, '_\1')
  end
end

# css, js
get '/main.css' do
  require 'sass'
  sass :main
end
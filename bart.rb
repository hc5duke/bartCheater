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
@@station_names   = ['EMBR', 'MONT', 'POWL', 'CIVC']
@@station_offsets = [     0,      2,      3,      5] # time between stations

#
# models
#
class Bart
  attr_accessor :trains, :stations
  def initialize static=false
    xml = static ? "sample/1807.xml" : "http://www.bart.gov/dev/eta/bart_eta.xml"
    @doc = Hpricot(open(xml))/"station"
    parse_stations
    find_trains
  end

  def parse_stations
    @stations = @@station_names.map do |st|
      Station.new(@doc.find{|x| (x/"abbr").inner_html == st})
    end
  end

  def find_trains
    @trains = []
    @stations.each do |st|
      [:home, :west].each do |dir|
        st.lines.select{|line| line.direction == dir}.map(&:estimates).flatten.sort.each do |eta|
          train = Train.new :destination => dir, :eta => (dir == :west) ? eta - st.offset : eta + st.offset
          @trains << train if new_train? train, st
        end
        @trains << '</div><div style="clear:left;"></div><div>'
      end
      @trains << '</div><div style="clear:left;"></div><div>'
    end
  end

  def new_train? train, station
    !@trains.find{|t| }
  end
end

class Train
  attr_accessor :destination, :eta
  def initialize options
    @destination = options[:destination]
    @eta = options[:eta]
  end

  def to_s
    "#{@destination} #{@eta}"
  end
end

class Station
  attr_accessor :abbr, :lines, :offset
  alias :name :abbr
  def initialize doc
    @abbr = (doc/"abbr").inner_html
    @lines = (doc/"eta").map{|e| Line.new e}.sort
    @offset = @@station_offsets[@@station_names.index(abbr)]
  end
end

class Line
  attr_accessor :destination, :estimates
  def initialize doc
    @destination = Destination.new((doc/"destination").inner_html)
    @estimates = (doc/"estimate").inner_html.gsub(/\s|min/,'').split(/,/).map(&:to_i)
  end

  def self.estimates_for lines, dir
    lines.select{|e| e.send dir}.map{|e| e.estimates}.flatten.sort.join ', '
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
end
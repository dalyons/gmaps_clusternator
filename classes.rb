#!/usr/bin/ruby

#require 'rubygems'
#require 'activesupport'
require 'set'
require 'json'

class Point
  attr_accessor :lat, :lng, :name 
  def to_s
    "lat: #{lat}, lng: #{lng}, name:#{name[0..8]}"
  end

  def initialize(lat,lng,name)
    @lat = lat
    @lng = lng
    @name = name
  end

  def to_cluster
    throw "attr not set!" if @lat.nil? || @lng.nil?
    Cluster.new([self])
  end
end

class PointCanvas
  #cattr_accessor :max_lat, :min_lng, :max_lng, :min_lat, :grid_width, :grid_height
  #
  attr_reader :lng_span, :lat_span, :grid_height, :grid_width

  @grid_width = 640
  @grid_height = 480
  @max_lat = @min_lat = @max_lng = @min_lng = nil
  @points = []

  @reverse_y = true


  def initialize(width, height, points)
    @grid_width = width
    @grid_height = height
    load_points(points)
  end

  def load_points(points)
    @points = points
    @min_lat = points.inject(99999.0){|min,point| min = point.lat if point.lat < min; min}
    @max_lat = points.inject(-99999.0){|max,point| max = point.lat if point.lat > max; max}
    @min_lng = points.inject(99999.0){|min,point| min = point.lng if point.lng < min; min}
    @max_lng = points.inject(-99999.0){|max,point| max = point.lng if point.lng > max; max}

    @lng_span = @max_lng - @min_lng
    @lat_span = @max_lat - @min_lat

  end

  def radius_deg_to_xy(radius_deg)
    [lat_to_px(radius_deg), lng_to_px(radius_deg) ]
  end

  def to_xy(point)
    #puts "argh!@"

    throw "missing grid info!" unless @grid_width && @grid_height
    throw "missing a total!" unless @min_lat && @min_lng && @max_lat && @max_lng


    x = (((point.lng - @min_lng) / @lng_span).abs * @grid_width).to_i
    y = (((point.lat - @min_lat) / @lat_span).abs * @grid_height).to_i

    y = @grid_height - y #if @reverse_y

    return [x,y]
  end

  def lat_to_px(deg)
    ((deg / @lat_span) * @grid_height).to_i
  end
  def lng_to_px(deg)
    ((deg / @lng_span) * @grid_width).to_i
  end

  def all_coordinates
    @points.collect{|p| to_xy(p) }
  end

  def all_coordinates_as_hash
    @points.collect{|p| coords = to_xy(p);  {:x => coords[0], :y => coords[1], :name => p.name} }
  end

  def max_x
    @max_x ||= @points.inject(0){|max,point| max = to_xy(point)[0] if to_xy(point)[0] > max;  max }
  end
  def min_x
    @min_x ||= @points.inject(90000){|min,point| min = to_xy(point)[0] if to_xy(point)[0] < min;  min }
  end
  def max_y
    @max_y ||= @points.inject(0){|max,point| max = to_xy(point)[1] if to_xy(point)[1] > max;  max }
  end
  def min_y
    @min_y ||= @points.inject(90099){|min,point| min = to_xy(point)[1] if to_xy(point)[1] < min;  min }
  end


  WINDOW_BORDER_PERCENT = 0.20
  def points
    if @ne_lat

      #puts "#{@ne_lat * multi} #{@ne_lng * multi} #{@sw_lat * multi} #{@sw_lng * multi}"

#puts "#{lat_range} : #{lng_range}"@ne_lng

      #normalize the corners for ease of bounds checking
      n_ne_lat = (@ne_lat < @sw_lat) ? @ne_lat + 90 + 180: @ne_lat + 90
      n_sw_lat = @sw_lat + 90
      n_ne_lng = (@ne_lng < @sw_lng) ? @ne_lng + 180 + 360 : @ne_lng + 180
      n_sw_lng = @sw_lng + 180

      #work out the margin, in degrees, to surround the window with so we include the masses of a few off screen clusters
      lat_margin = (n_ne_lat - n_sw_lat).abs * WINDOW_BORDER_PERCENT
      lng_margin = (n_ne_lng - n_sw_lng).abs * WINDOW_BORDER_PERCENT


     # puts "#{n_ne_lat} #{n_ne_lng} #{n_sw_lat} #{n_sw_lng}"
      #n_lat_range = ((n_sw_lat * (1 - WINDOW_BORDER_PERCENT))..(n_ne_lat * (1 + WINDOW_BORDER_PERCENT)))
      #n_lng_range = ((n_sw_lng * (1 - WINDOW_BORDER_PERCENT))..(n_ne_lng * (1 + WINDOW_BORDER_PERCENT)))
      #puts "#{n_lat_range} : #{n_lng_range}"

      @points.select do |p|
        n_point_lat = (@ne_lat < @sw_lat && (-90..@ne_lat).include?(p.lat) ) ? p.lat + 90 + 180 : p.lat + 90
        n_point_lng = (p.lng < @sw_lng && (-180..@ne_lng).include?(p.lng)) ? p.lng + 180 + 360 : p.lng + 180

#puts "point #{n_point_lat} #{n_point_lng}"
        #n_lat_range.include?(n_point_lat) && n_lng_range.include?(n_point_lng)
        (n_point_lat < (n_ne_lat + lat_margin) && 
         n_point_lat > (n_sw_lat - lat_margin) &&
         n_point_lng < (n_ne_lng + lng_margin) &&
         n_point_lng > (n_sw_lng - lng_margin))
      end
    else
      @points
    end
  end

  def set_window(ne_lat, ne_lng, sw_lat, sw_lng)
    @ne_lat = ne_lat.to_f
    @ne_lng = ne_lng.to_f
    @sw_lat = sw_lat.to_f
    @sw_lng = sw_lng.to_f
  end
  def reset_window
    @ne_lat, @ne_lng, @sw_lat, @sw_lng = nil
  end

end

class Cluster
  attr_reader :points, :lat, :lng

  attr_accessor :neighbours


  def initialize(points = [])
    @sum_lat = @sum_lng = 0
    @points = Set.new
    points.each{|point| add_point point }
    @neighbours = Set.new
  end

  def add_point(point)
    #if a cluster has been add to this, flatten it by pulling out all its points
    if point.class == Cluster
      point.points.each{|child_point| add_point child_point}
    else
      @sum_lat += point.lat
      @sum_lng += point.lng
      @points << point
      recalc_avg
    end
  end


  def add_points(points)
    points.each{|point| add_point point }
  end

  def distance_in_deg_to_cluster(other)
    (((lat - other.lat).abs ** 2) + ((lng - other.lng).abs ** 2)) ** 0.5
  end

  def size
    @points.length
  end

  def to_s
    points.collect{|p|
      if p.class == Point
        p.name
      else
        p.class.to_s
      end
    }.join(",")
  end

  def to_json(*a)
    {
      'lat' => lat,
      'lng' => lng,
      'size' => size
    }.to_json(*a)
  end

 private
  def recalc_avg
    @lat = @sum_lat / @points.length
    @lng = @sum_lng / @points.length
  end
end


class PointReader

  def self::read(filename = 'data.csv')
    points = []

    File.open(filename) do |f|
      f.readlines.each do |line|
        name, lat, lng = line.strip.split(',')
        lat = lat.to_f
        lng = lng.to_f
        points << Point.new(lat,lng,name)
      end
    end
    return points
  end

  def self::random(total)
    points = []
    total.times do
      points << Point.new(rand(500).to_f, rand(500).to_f, 'testpoint')
    end
    points
  end
end





#points.each{|p| puts p }


#canvas = PointCanvas.new(640,480,points)
#p canvas.all_coordinates_as_hash

#Point.class_eval {@@min_lat = points.inject(99999.0){|min,point| min = point.lat if point.lat < min; min}}
#Point.class_eval {@@max_lat = points.inject(-99999.0){|max,point| max = point.lat if point.lat > max; max}}
#Point.class_eval {@@min_lng = points.inject(99999.0){|min,point| min = point.lng if point.lng < min; min}}
#Point.class_eval {@@max_lng = points.inject(-99999.0){|max,point| max = point.lng if point.lng > max; max}}
#Point.class_eval {@@grid_width = 640 }
#Point.class_eval {@@grid_height = 480 }


#points.each{|p| puts "x:#{p.to_xy[0]} y:#{p.to_xy[1]} lat:#{p.lat} lng:#{p.lng}"}

#puts Point.class_eval {@@min_lat}

#puts "min_lat: #{Point::min_lat} max_lat:#{Point::max_lat} min_lng:#{Point::min_lng} max_lng:#{Point::max_lng}"

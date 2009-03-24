#!/usr/bin/ruby

#require 'rubygems'
#require 'activesupport'

class Point
	attr_accessor :lat, :lng, :name
	def to_s
		"lat: #{lat}, lng: #{lng}, name:#{name[0..8]}"
	end
	
	def to_cluster
	  throw "attr not set!" if @lat.nil? || @lng.nil?
	  Cluster.new([self])
	end
end

class PointCanvas
	#cattr_accessor :max_lat, :min_lng, :max_lng, :min_lat, :grid_width, :grid_height
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
	  @points.inject(0){|max,point| max = to_xy(point)[0] if to_xy(point)[0] > max;  max }
	end
	def min_x
	  @points.inject(900){|min,point| min = to_xy(point)[0] if to_xy(point)[0] < min;  min }
	end
	def max_y
	  @points.inject(0){|max,point| max = to_xy(point)[1] if to_xy(point)[1] > max;  max }
	end
	def min_y
	  @points.inject(900){|min,point| min = to_xy(point)[1] if to_xy(point)[1] < min;  min }
	end

end

class Cluster
  attr_reader :points, :lat, :lng
  
  
  def initialize(points = [])
    @sum_lat = @sum_lng = 0
    @points = []
    points.each{|point| add_point point }
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
 private
  def recalc_avg
    @lat = @sum_lat / @points.length
    @lng = @sum_lng / @points.length
  end
end


class PointReader

  def self::read
    points = []

    File.open('data.csv') do |f|
    	f.readlines.each do |line|
    		p = Point.new
    		p.name, p.lat, p.lng = line.strip.split(',')
    		p.lat = p.lat.to_f
    		p.lng = p.lng.to_f
    		points << p
    	end
    end
    return points
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

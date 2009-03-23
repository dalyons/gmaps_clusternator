#!/usr/bin/ruby

require 'rubygems'
require 'activesupport'

class Point
	attr_accessor :lat, :lng, :name
	def to_s
		"lat: #{lat}, lng: #{lng}, name:#{name[0..8]}"
	end
end

class PointCanvas
	#cattr_accessor :max_lat, :min_lng, :max_lng, :min_lat, :grid_width, :grid_height
	@grid_width = 640
	@grid_height = 480
	@max_lat = @min_lat = @max_lng = @min_lng = nil
  @points = []

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
	end

	def to_xy(point)
	  throw "missing grid info!" unless @grid_width && @grid_height
	  throw "missing a total!" unless @min_lat && @min_lng && @max_lat && @max_lng

    lng_span = @max_lng - @min_lng
		lat_span = @max_lat - @min_lng

    y = (((point.lat - @min_lat) / lat_span).abs * @grid_height).to_i
    x = (((point.lng - @min_lng) / lng_span).abs * @grid_width).to_i

    return [x,y]
  end

	def all_coordinates
		@points.collect{|p| to_xy(p) }
	end

	def all_coordinates_as_hash
		@points.collect{|p| coords = to_xy(p);  {:x => coords[0], :y => coords[1], :name => p.name} }
	end

end

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

points.each{|p| puts p }


canvas = PointCanvas.new(640,480,points)
p canvas.all_coordinates_as_hash

#Point.class_eval {@@min_lat = points.inject(99999.0){|min,point| min = point.lat if point.lat < min; min}}
#Point.class_eval {@@max_lat = points.inject(-99999.0){|max,point| max = point.lat if point.lat > max; max}}
#Point.class_eval {@@min_lng = points.inject(99999.0){|min,point| min = point.lng if point.lng < min; min}}
#Point.class_eval {@@max_lng = points.inject(-99999.0){|max,point| max = point.lng if point.lng > max; max}}
#Point.class_eval {@@grid_width = 640 }
#Point.class_eval {@@grid_height = 480 }


#points.each{|p| puts "x:#{p.to_xy[0]} y:#{p.to_xy[1]} lat:#{p.lat} lng:#{p.lng}"}

#puts Point.class_eval {@@min_lat}

#puts "min_lat: #{Point::min_lat} max_lat:#{Point::max_lat} min_lng:#{Point::min_lng} max_lng:#{Point::max_lng}"

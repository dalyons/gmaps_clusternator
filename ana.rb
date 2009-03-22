#!/usr/bin/ruby

require 'rubygems'
require 'activesupport'

class Point
	attr_accessor :lat, :lng, :name
	def to_s
		"lat: #{lat}, lng: #{lng}, name:#{name[0..8]}"
	end

	#@@min_lat = @@max_lat = @@min_lng = @@max_lng = @@grid_width = @@grid_height = nil
	cattr_accessor :max_lat, :min_lng, :max_lng, :min_lat, :grid_width, :grid_height


	def to_xy
		throw "missing grid info!" unless @@grid_width && @@grid_height
		throw "missing a total!" unless @@min_lat && @@min_lng && @@max_lat && @@max_lng
		
		lng_span = @@max_lng - @@min_lng
		lat_span = @@max_lat - @@min_lng
		
		y = (((@lat - @@min_lat) / lat_span).abs * @@grid_height).to_i
		x = (((@lng - @@min_lng) / lng_span).abs * @@grid_width).to_i

		return [x,y]
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


#Point.class_eval {@@min_lat = points.inject(99999.0){|min,point| min = point.lat if point.lat < min; min}}
#Point.class_eval {@@max_lat = points.inject(-99999.0){|max,point| max = point.lat if point.lat > max; max}}
#Point.class_eval {@@min_lng = points.inject(99999.0){|min,point| min = point.lng if point.lng < min; min}}
#Point.class_eval {@@max_lng = points.inject(-99999.0){|max,point| max = point.lng if point.lng > max; max}}
#Point.class_eval {@@grid_width = 640 }
#Point.class_eval {@@grid_height = 480 }

Point.min_lat = points.inject(99999.0){|min,point| min = point.lat if point.lat < min; min}
Point.max_lat = points.inject(-99999.0){|max,point| max = point.lat if point.lat > max; max}
Point.min_lng = points.inject(99999.0){|min,point| min = point.lng if point.lng < min; min}
Point.max_lng = points.inject(-99999.0){|max,point| max = point.lng if point.lng > max; max}
Point.grid_width = 640 
Point.grid_height = 480 


points.each{|p| puts "x:#{p.to_xy[0]} y:#{p.to_xy[1]} lat:#{p.lat} lng:#{p.lng}"}

#puts Point.class_eval {@@min_lat}

puts "min_lat: #{Point::min_lat} max_lat:#{Point::max_lat} min_lng:#{Point::min_lng} max_lng:#{Point::max_lng}"

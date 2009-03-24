
Shoes.setup do
  gem 'rbtree'
end
require 'rbtree'
require 'clusterer.rb'
require 'classes.rb'


WIDTH = 800
HEIGHT= 600
BORDER = 10
MARKER_RADIUS = 7
CLUSTER_RADIUS = 30



$points = PointReader::read
$canvas = PointCanvas.new(WIDTH,HEIGHT,$points)
$clusterer = Clusterer.new($points, 10)
#$clusterer.clusterize_bottom_up(6)



puts "maxX:#{$canvas.max_x} minX:#{$canvas.min_x} maxY:#{$canvas.max_y} minY:#{$canvas.min_y}"

Shoes.app(:width => WIDTH + BORDER * 2, :height => HEIGHT + BORDER * 2 + 50, :resizable => false) do
  
  @cluster_width = CLUSTER_RADIUS
  @cluster_height = CLUSTER_RADIUS
  
  stack do
    @menu = flow do
      para "set radius of degrees to cluster within"
      @limit_field = edit_line :width => 40
      @limit_field.text = 4
      button "Go!" do
        @map.clear
        $clusterer.reset
        limit = @limit_field.text.to_i
        @cluster_width = $canvas.lng_to_px(limit)
        @cluster_height = $canvas.lat_to_px(limit)
        $clusterer.clusterize_bottom_up(limit)
        draw_clusters
        #draw_points
      end
    end
    
    @map = flow do
      para "map"
    end
  end
  
  def draw_point(point, color)
    x, y = $canvas.to_xy(point)
    #puts "#{x} #{y} #{color}"
    #fill color
    #stroke_width 0
    @map.stroke color
    @map.strokewidth 0
    @map.fill color
    @map.oval x + BORDER,y + BORDER,MARKER_RADIUS, {:center=>true}
  end
  
  #@tooltip = @menu.add para "#{points.length}"
  
  def draw_cluster(cluster)
    x, y = $canvas.to_xy(cluster)
    
    #puts "drawing cluster"
    @map.stroke rgb(255,0,0,0.1)
    @map.strokewidth 0
    @map.fill rgb(255,0,0,0.2)
    
    #current_radius = @limit_field.text.to_i
    @map.oval :left => x + BORDER,
              :top => y + BORDER,
              :width => @cluster_width,
              :height => @cluster_height,
              :center=> true
              
    clr = rgb(rand,rand,rand,1.0)
    puts cluster.points.length
    puts cluster
    cluster.points.each{|point| draw_point(point, clr) }
  end
  
  def draw_clusters
    $clusterer.clusters.each do |cluster|
      puts "cluster lat:#{cluster.lat} lng:#{cluster.lng}"
      
      draw_cluster(cluster)
      
    end
  end
  
  def draw_all_points(points)
    $points.each do |point| 
      x, y = $canvas.to_xy(point)
      draw_point(x,y, rgb(rand, rand, rand, 1))
    end
  end
  
  motion do |top, left|
    #@tooltip.replace "#{rand} nodes"
  end
  
  
  #
  #@tooltip = para "#{points.length}"
  
  

  #para clusterer.clusters.length
  
  
  draw_clusters
end

require 'classes.rb'
require 'rubygems'
#require 'rbtree'
require 'set'
#require 'ruby-debug'


class Clusterer2

  def initialize(point_canvas)
    @point_canvas = point_canvas
    @points = point_canvas.points
  end

  def clusterize(radius_deg)
    reset
    grid_cluster(radius_deg)
    @clusters
  end

  def clusters
    raise "run clusterer first!" unless @clusters

    @clusters
  end

  def reset
    @points = @point_canvas.points
    @clusters = []
  end

 private
  
  def grid_cluster(radius_deg)

    puts "running clusterer..."
    start = Time.now

    radius_x, radius_y = @point_canvas.radius_deg_to_xy(radius_deg)
    grid_width = (@point_canvas.grid_width / radius_x) * 2   
    grid_height = (@point_canvas.grid_height / radius_y) * 2 


    grid = Array.new(grid_width){ Array.new(grid_height) }

    cluster_set = Set.new

    @points.each do |point|
      cell_x, cell_y = point_to_cell_xy(grid_width, grid_height,point)
#puts cell_y
#puts cell_x
      cell = (grid[cell_x][cell_y] ||= Cluster.new)
      cell.add_point(point)
      cluster_set.add cell

#puts "done #{grid_width} #{grid_height}"
    end


    #merge adjacent clusters
    did_a_merge = true
    blacklist = Set.new

    while (did_a_merge)
      did_a_merge = false
      cluster_set.sort{|c1, c2| c1.size <=> c2.size}.each do |cluster|
        next if blacklist.include? cluster

        cell_neighbours(grid,cluster).each do |neighbour|
          next if neighbour.nil? || blacklist.include?(neighbour)
          
          distance_bw = cluster.distance_in_deg_to_cluster(neighbour)

          #Calculate the distance between clusters we will accept based on a formula that takes into account the 
          #proximity of the two clusters and the inverse difference b/w their respective sizes. Formula:
          # D = ((R-r)G/R) * (1 - (Mc - Mn)/Mc)
          # Where:
          #   D = accept distance
          #   R = the clustering radius
          #   r = distance b/w the cluster and its neighbour
          #   G = bonus multiplier for biasing proximity in favour of mass difference
          #   Mc = mass of the current cluster
          #   Mn = mass of the neighbour cluster
          #
          accept_distance = radius_deg * (((radius_deg - distance_bw).to_f * 2)/radius_deg) * (1-((cluster.size - neighbour.size).to_f / cluster.size))
    
          #if cluster.distance_in_deg_to_cluster(neighbour) < (radius_deg * 0.7)
          if distance_bw <= accept_distance

            #remove self from old cell
            old_x, old_y = point_to_cell_xy(grid_width, grid_height, cluster)
            grid[old_x][old_y] = nil

            cluster.add_point neighbour
            blacklist.add neighbour

            #now readd self incase position has changed
            x, y = point_to_cell_xy(grid_width, grid_height, cluster)
            grid[x][y] = cluster

            did_a_merge = true
          end
        end
      end
      cluster_set.subtract blacklist
    end 

    puts "#{grid_width} #{grid_height}, #{radius_x} #{radius_y}"
    
    puts "Clusterer finished in #{Time.now - start} sec."
  
   # puts cluster_set.inspect

    @clusters = cluster_set.to_a
  end

  def point_to_cell_xy(grid_width, grid_height, point)
    x, y = @point_canvas.to_xy(point)
    cell_x = ((x / @point_canvas.grid_width.to_f) * (grid_width -1)).to_i
    cell_y = ((y / @point_canvas.grid_height.to_f) * (grid_height -1)).to_i
    [cell_x, cell_y]
  end

  def cell_neighbours(grid, cell)
    grid_width = grid.length
    grid_height = grid[0].length
    x, y = point_to_cell_xy(grid_width, grid_height,cell)
    
    neighbour_cords = [
      [x-1,y+1],[x,y+1],[x+1,y+1], #above
      [x-1,y  ],        [x+1,y  ], #inline
      [x-1,y-1],[x,y-1],[x+1,y-1]  #below
    ]
    res = []
    neighbour_cords.each do |(x,y)| 
      if x >= 0 && x < grid_width && y >= 0 && y < grid_height
        res << grid[x][y] #unless grid[x][y] == cell
        #yield grid[x][y]
      end
    end
    res
  end

end



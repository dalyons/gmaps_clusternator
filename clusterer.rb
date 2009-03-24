require 'classes.rb'
require 'rubygems'
require 'rbtree'
require 'set'

class Clusterer
  attr_reader :clusters, :remainders
  
  
  
  #@points = []
  @clusters = []
  @limit = 1
  
  def initialize(points, limit_radius_degs)
    #@points = points.dup
    @clusters = points.collect{|p| p.to_cluster} #.sort_by{ rand }
    @original_clusters = @clusters.dup
    @limit = limit_radius_degs
  end
  
  def reset
    @clusters = @original_clusters.dup
  end

  #def clusterize(cluster_algorithm)
  #  puts cluster_algorithm.to_s
  #  cluster_algorithm.in_context(self).call
  #end
  
  
  
  #Define the algorithms to pass to clusterize()
  ALG_BOTTOM_UP = lambda {
    #calculate NxN adj matrix - should only be n^2 time so we are still ok.
      #if the distance is greater than the limit, dont add it. 
    #while doing so, keep a seperate, sorted list of the shortest links, shortest first.
    
    #select the shortest pair, merge them into a cluster.
    #repeat until you have no remaining, only clusters.
    #calculate the adj matrix for all the clusters. 
    #repeat process until you have an adj matrix with all empty links.
    
    #???
    #Profit
  }
  #ALG_BOTTOM_UP2 = lambda {
  def clusterize_bottom_up(limit)
    #calculate the distance from each point to every other within range and store it in a sorted set       WC:  N*(N..1)
      #start with a set containing all nodes, then until empty:
        #take the first, and iterate through the rest:
          #if distance b/w points is < limit, store a link b/w 1st and current into the ordered set.
        #discard the first 
    
    #set up an empty hash to contain nodes marked as 'dead' aka combined into bigger clusters
    #until no more links:                                                                      WC: N*(N..1) * NlogN 
      #pop the shortest link from the set
      #if either of its clusters are dead, loop next.
      #create a new cluster containing the two in the link.
      #for every other cluster:                                                                  WC: (N-1) * logN
      #  calc distance b/w new cluster and this one, push to link set if calc_dist < limit      

    #done
    puts "running clusterer..."
    
    @limit = limit
    #implement the above
    #calculate the distance from each point to every other within range and store it in a sorted set       WC:  N*(N..1)
    links = RBTree.new
    remaining = @clusters.dup

    #start with a set containing all nodes, then until empty:
    while (left_cluster = remaining.pop) do
        #take the first, and iterate through the rest:
        remaining.each{|right_cluster| 
          #if distance b/w points is < limit, store a link b/w 1st and current into the ordered set.
          distance = ClusterLink::calc_distance(left_cluster, right_cluster)
          if distance < @limit
            links[distance] = ClusterLink.new(left_cluster, right_cluster)
          end
        }
        #discard the first 
    end
    
    
    #create a collection to use as a running pool of clusters as we build them 
    #init it with our current clusters - map to a set(hash-backed) for performance. 
    cluster_pool = @clusters.inject(Set.new){|pool,cluster| pool.add cluster}
    
    
    #until no more links:                                                                      WC: N*(N/2) * NlogN 
    while (link = links.shift.to_a[1]) do
      #pop the shortest link from the set
      #if either of its clusters are no longer in the pool, loop next.
      next unless (cluster_pool.include?(link.a) && cluster_pool.include?(link.b))
      
      #create a new cluster containing the two in the link.
      merged_cluster = Cluster.new #([link.a,link.b])
      merged_cluster.add_point link.a
      merged_cluster.add_point link.b
      
      #s1 = Set.new(link.a.points)
      #s2 = Set.new(link.b.points)
      #puts link.a.to_s + "\n" + link.b.to_s + "\n" + link.distance.to_s
      #unless (s1 & s2).empty?
      #  throw "dup point!" + "\n" + link.a.to_s + "\n" + link.b.to_s + "\n" + link.distance.to_s
      #end
      
      
      #remove the linked clusters from the pool
      cluster_pool.subtract([link.a, link.b])
      
      #for every other cluster:                                                                  WC: (N-1) * logN
      cluster_pool.each do |cluster|
        #calc distance b/w new cluster and this one, push to link set if calc_dist < limit      
        distance = ClusterLink.calc_distance(merged_cluster, cluster)
        if distance < @limit
          links[distance] = ClusterLink.new(merged_cluster, cluster)
        end
      end
      
      #now add self to the pool
      cluster_pool.add(merged_cluster)
    end

    #set the results before we're done
    @clusters = cluster_pool.to_a
    
    puts "done with clusterer"

  #possible optimizations?
    #convert every point into a cluster of size 1
    #sort the clusters into two lists -> one by lat, one by lng. nlogn for each(as long as rbtree is included). 
      ##using the lat and lng lists, calculate new links for this cluster to its surrounding ones within range.
      #  #how?
      ##push this cluster into the lat and lng lists
      ##push these links onto the link tree
  end

end

class ClusterLink
  attr_reader :a, :b, :distance
  
  alias eql? ==

  def self.calc_distance(p1, p2)
    Math.sqrt((p1.lat - p2.lat).abs ** 2 + (p1.lng - p2.lng).abs ** 2)
  end

  def initialize(cluster_a, cluster_b)
    @a = cluster_a
    @b = cluster_b
    @distance = ClusterLink::calc_distance(@a, @b)
  end

  

  #two links are considered equal if they contain the same points, in any order
  def ==(clusterlink)
      (@a == clusterlink.a && @b == clusterlink.b) || (@b == clusterlink.a && @a == clusterlink.b)
    rescue
      false
  end
  
end

class Proc
  # Changes the context of a proc so that 'self' is the klass_or_obj passed.
  def in_context(klass_or_obj)
    klass_or_obj.send(:eval, self.to_ruby)
  end
end

#test code



class Clusterer
  attr_reader :clusters, :remainders

  #check if the RBTree gem has the enumerator patches I made
  PATCHED_RBTREE = RBTree.new.respond_to?(:each_from_key) && RBTree.new.respond_to?(:reverse_each_from_key)

  #@points = []
  @clusters = []
  @limit = 1

  #
  MERGE_RADIUS_RATIO = 1 + 1 - (( (Math.sqrt(3) * Math::PI)/2) / Math::PI)


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
    start = Time.now

    merge_radius = @limit * MERGE_RADIUS_RATIO
    puts "merge raduis ratio is #{MERGE_RADIUS_RATIO}, limit is #{@limit}, merge limit is #{merge_radius}."


    @limit = limit
    #implement the above
    #calculate the distance from each point to every other within range and store it in a sorted set       WC:  N*(N..1)
    links = RBTree.new
    remaining = @clusters.dup

    #If we have the patched rbtree, we can set up some optimizations for use later on.
    #We are going to maintain two sorted rbtrees of lat & lng. So, if we have the patched rbtree
    #that lets us start enumerating from any key, we can use these to find the nodes close to
    #a specfic node, without having to search all the other nodes on the canvass, reducing our search from
    # N-1 to logN + X, where X is the number of nodes rectagulary bounded by the limit_radius.
    if PATCHED_RBTREE
      puts "Patched RBTree found, running in optimized mode..."
      lat_tree = RBTree.new
      lng_tree = RBTree.new
    end

    #start with a set containing all nodes, then until empty:
    while (left_cluster = remaining.pop) do
        #take the first, and iterate through the rest:
        remaining.each do |right_cluster|
          #if distance b/w points is < limit, store a link b/w 1st and current into the ordered set.
          distance = ClusterLink::calc_distance(left_cluster, right_cluster)
          #distance = rand(3 * merge_radius)
          if distance < @limit
            links[distance] = ClusterLink.new(left_cluster, right_cluster)

          end
          if distance <= merge_radius
            left_cluster.neighbours.add(right_cluster)
            right_cluster.neighbours.add(left_cluster)
          end

        end

        if PATCHED_RBTREE
          lat_tree[left_cluster.lat] = left_cluster
          lng_tree[left_cluster.lng] = left_cluster
        end

        #discard the first
    end

   # @clusters.each {|c| puts "nl:#{c.neighbours.length}" }

    puts "Setup took: #{Time.now - start} sec"

    #create a collection to use as a running pool of clusters as we build them
    #init it with our current clusters - map to a set(hash-backed) for performance.
    cluster_pool = @clusters.inject(Set.new){|pool,cluster| pool.add cluster}


    #until no more links:                                                                      WC: N*(N/2) * NlogN
    while (link = links.shift.to_a[1]) do

      #puts "in"
      #pop the shortest link from the set
      #if either of its clusters are no longer in the pool, loop next.
      next unless (cluster_pool.include?(link.a) && cluster_pool.include?(link.b))

      #puts "going for it"

      #create a new cluster containing the two in the link.
      merged_cluster = Cluster.new #([link.a,link.b])
      merged_cluster.add_point link.a
      merged_cluster.add_point link.b

      #puts "here"

      #s1 = Set.new(link.a.points)
      #s2 = Set.new(link.b.points)
      #puts link.a.to_s + "\n" + link.b.to_s + "\n" + link.distance.to_s
      #unless (s1 & s2).empty?
      #  throw "dup point!" + "\n" + link.a.to_s + "\n" + link.b.to_s + "\n" + link.distance.to_s
      #end


      #remove the linked clusters from the pool
      cluster_pool.subtract([link.a, link.b])


      if PATCHED_RBTREE
        #SMART WAY: only look at those clusters rectangulary bounded by the limit radius, using the patched enumerators


        #First purge the lat/lng of the recently merged clusters                4logN
        lat_tree.delete link.a.lat
        lat_tree.delete link.b.lat
        lng_tree.delete link.a.lng
        lng_tree.delete link.b.lng

        #then add the new cluster                                               2logN
        lat_tree[merged_cluster.lat] = merged_cluster
        lng_tree[merged_cluster.lng] = merged_cluster

        find_close_nodes(lat_tree, lng_tree, merged_cluster).each {|cluster|   # XlogN
          distance = ClusterLink.calc_distance(merged_cluster, cluster)
          links[distance] = ClusterLink.new(merged_cluster, cluster)
        }

      else
        #DUMB WAY: for every other cluster:                                                       WC: (N-1) * logN
        #cluster_pool.each do |cluster|
          #calc distance b/w new cluster and this one, push to link set if calc_dist < limit
        # distance = ClusterLink.calc_distance(merged_cluster, cluster)
        # if distance < @limit
        #   links[distance] = ClusterLink.new(merged_cluster, cluster)
        # end
        #end


        link.a.neighbours.delete link.b
        link.b.neighbours.delete link.a

        [link.a, link.b].each do |old_cluster|
          #for every neighbour,
          old_cluster.neighbours.each do |neighbour|

            #next unless cluster_pool.include? neighbour

            #delete the old clusters from the neighbour's neighbour pool
            neighbour.neighbours.delete(old_cluster)

            #check if it is within the mergeradius of the new cluster
            if ClusterLink.calc_distance(merged_cluster, neighbour) <= merge_radius
              #if so, add the new cluster as a neigbour to that point...
              neighbour.neighbours.add(merged_cluster)
              #and vice versa.
              merged_cluster.neighbours.add(neighbour)
            end

          end
        end
        merged_cluster.neighbours.each do |neighbour|
          distance = ClusterLink.calc_distance(merged_cluster, neighbour)
          if distance < @limit
            links[distance] = ClusterLink.new(merged_cluster, neighbour)
          end
        end

      end

      #now add self to the pool
      cluster_pool.add(merged_cluster)
    end

    #set the results before we're done
    @clusters = cluster_pool.to_a

    puts "Clusterer finished in #{Time.now - start} sec."

  #possible optimizations?
    #convert every point into a cluster of size 1
    #sort the clusters into two lists -> one by lat, one by lng. nlogn for each(as long as rbtree is included).
      ##using the lat and lng lists, calculate new links for this cluster to its surrounding ones within range.
      #  #how?
      ##push this cluster into the lat and lng lists
      ##push these links onto the link tree
  end

 private
  def find_close_nodes(lat_tree,lng_tree, center_cluster)
    clusters_in_range = []
    lat_tree.each_from_key(center_cluster.lat) { |lat,cluster|
      clusters_in_range.push(cluster) if ClusterLink::within_limit?(center_cluster,cluster,@limit) && cluster != center_cluster
      break if lat > center_cluster.lat + @limit
    }
    lat_tree.reverse_each_from_key(center_cluster.lat) { |lat,cluster|
      clusters_in_range.push(cluster) if ClusterLink::within_limit?(center_cluster,cluster,@limit) && cluster != center_cluster
      break if lat < center_cluster.lat - @limit
    }

    lng_tree.each_from_key(center_cluster.lng) { |lng,cluster|
      clusters_in_range.push(cluster) if ClusterLink::within_limit?(center_cluster,cluster,@limit) && cluster != center_cluster
      break if lng > center_cluster.lng + @limit
    }
    lng_tree.reverse_each_from_key(center_cluster.lng) { |lng,cluster|
      clusters_in_range.push(cluster) if ClusterLink::within_limit?(center_cluster,cluster,@limit) && cluster != center_cluster
      break if lng < center_cluster.lng - @limit
    }
    return clusters_in_range
  end

end

class ClusterLink
  attr_reader :a, :b, :distance

  alias eql? ==

  def self.calc_distance(p1, p2)
    Math.sqrt((p1.lat - p2.lat).abs ** 2 + (p1.lng - p2.lng).abs ** 2)
  end
  def self::within_limit?(p1,p2,limit)
    dist = self::calc_distance(p1,p2)
    return dist <= limit #&& dist > 0
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


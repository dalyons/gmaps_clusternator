
require 'rubygems'
require 'sinatra/base'
require 'haml'


#require 'rbtree'
require 'clusterer.rb'
require 'classes.rb'





module ClusterTest
  class Application < Sinatra::Base

    set :public, "public"

    WIDTH = 640
    HEIGHT= 480

    def initialize
      super
      @points = PointReader::read('data.csv')
      @canvas = PointCanvas.new(WIDTH,HEIGHT,@points)

      @clusterer = Clusterer2.new(@canvas)
    end


    get '/' do

      haml :index
    end

    get '/nodes.js' do
      radius = params[:radius] ? params[:radius].to_f : 6
puts params.inspect
      @canvas.set_window(params[:ne_lat], params[:ne_lng], params[:sw_lat], params[:sw_lng])
      @clusterer.clusterize(radius)

      content_type :json
      {:markers => @clusterer.clusters}.to_json
    end
  end
end

include ClusterTest
Application.run! :port => 9090



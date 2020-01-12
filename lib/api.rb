require 'redis'
require 'uri'
require 'net/http'

# Public: Wrapper around the Poe Watch API. 
# Uses redis to store items, leagues and categories data
#
# Examples
#
#   PoeWatch::Api.refresh! # => fetches the latest data from the API
#
#   PoeWatch::Item.all # => All items
#   PoeWatch::Item.find({ name: 'Mirror of Kalandra' }).getPriceDataByLeague('Metamorph')
#
#   PoeWatch::League.find({ name: 'Metamorph' })
#
module PoeWatch
  class Api
    class Error < StandardError; end
  
    BULK_APIS = {
      item_data: "https://api.poe.watch/itemdata",
      categories: "https://api.poe.watch/categories",
      leagues: "https://api.poe.watch/leagues",
    }

    ITEM_API = {
      item: "https://api.poe.watch/item",
    }

    DEFAULT_EXPIRY = 45 * 60 # 45 minutes
    
    @updating = false
    @redis = $redis 

    class << self  
      def redis
        raise PoeWatch::Api::Error.new("You need to configure redis by either setting the global $redis variable or calling PoeWatchApi.redis = Redis.new(...)") unless @redis
        @redis
      end

      def redis=(redis)
        @redis = redis
      end
      
      def refresh!(expiry = DEFAULT_EXPIRY)
        if !@updating && !ready?
          #puts "Updating..."
          @updating = true

          BULK_APIS.each do |name, api_url|
            raw_response = request(api_url)
            redis.set(redis_key(name), raw_response) 
            redis.expire(redis_key(name), expiry)
          end
          @updating = false    
          true
        else
          return raise PoeWatch::Api::Error.new("An update is already in progress") if @updating
          # puts "Already up to date"
        end
      end

      def request(api, params = {}, parse = false) 
        uri = URI.parse(api)

        if (params.any?)
          uri.query = URI.encode_www_form(params)
        end
        
        request = Net::HTTP::Get.new(uri.request_uri)
        request["Content-Type"] = "application/json"

        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true
        
        response = http.request(request)
        
        raise PoeWatch::Api::Error.new("Couldn't connect to poe.watch") unless response.is_a?(Net::HTTPSuccess)

        parse ? JSON.parse(response.body) : response.body
      end

      def items
        @items ||= get_data(:item_data)
        @items || []
      end

      def categories
        @categories ||= get_data(:categories)
        @categories || []
      end

      def leagues
        @leagues ||= get_data(:leagues)
        @leagues || []
      end
      
      def get_data(type)
        data = redis.get(redis_key(type))
        data ? JSON.parse(data) : nil
      end

      def clear!
        BULK_APIS.keys
        .each { |key| redis.del(redis_key(key)) }
      end
      
      def ready?
        !has_expired?
      end

      # Check if any of the redis stored data is missing
      def has_expired?
        BULK_APIS.keys
          .map { |key| redis.exists(redis_key(key)) }
          .reject { |k| !k }
          .empty?
      end

      def redis_key(type)
        "poe_watch_#{type}"
      end

      def memory_footprint
        BULK_APIS.keys.map do |key| 
          size = nil
          if redis.exists(redis_key(key))
            size = redis.debug("object", redis_key(key)).match(/serializedlength:(\d+)/)[1].to_i / 1024.0
          end
          [key, size]
        end.to_h.compact
      end
    end
  end
end
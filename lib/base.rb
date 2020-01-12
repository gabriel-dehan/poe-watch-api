require_relative './utils'

# Public: Base class for all Poe Watch items.
# This is pretty much active record for PoeWatch.
# It automatically fetches the necessary data and defines getters, setters as well as question mark methods for boolean values.
# It also defines `::find(params)`, `::where(params)` and `::all` class methods.
# 
# Examples
#
#   class PoeWatch::Item < PoeWatch::Base
#   end
#
module PoeWatch
  class Base
    INFLECTOR = {
      category: 'categories',
      item: 'items',
      league: 'leagues'
    }

    class << self 
      # Defines an instance variable that'll be memoized and used to store Poe Watch data
      def __data 
        if not defined? @__data
          @__data = []
        end
        @__data
      end

      # Setter for instance variable
      def __data=(value)
        @__data = value
      end

      # Public: Gets the object type
      #
      # Examples
      #
      #  PoeWatch::League.type # => :league
      # 
      # Returns a Symbol.
      def type
        self.name.split('::').last.downcase.to_sym
      end
      
      # Public: Gets all data as instance of the class
      #
      # Examples
      #
      #  PoeWatch::League.all # => array of PoeWatch::League items
      # 
      # Returns an Array of class instances.
      def all
        PoeWatch::Api.refresh!
        
        return __data if __data.any?
        
        # If data isn't already loaded
        # puts "Loading #{type} data..."
        json_data = PoeWatch::Api.send(INFLECTOR[type])
        if json_data.any?
          __data = json_data.map { |raw_data| self.new(raw_data) }
        else
          []
        end
      end

      # Public: Count the number of items
      #
      # Examples
      #
      #  PoeWatch::League.count # => 30
      # 
      # Returns an Integer.
      def count
        PoeWatch::Api.refresh!
        
        return __data if __data.any?
        
        # If data isn't already loaded
        # puts "Loading #{type} data..."
        json_data = PoeWatch::Api.send(INFLECTOR[type])
        if json_data.any?
          __data = json_data.length
        else
          0
        end
      end

      # Public: Gets items filtered by a query
      # You can pass regular expressions for string parameters. It will do a match.
      #
      # params - A hash of parameters. Eg: { hardcore: true }
      #
      # Examples
      #
      #  PoeWatch::League.where({ hardcore: true }) # => array of PoeWatch::League items
      #  PoeWatch::League.where({ name: /metamorph/i, hardcore: true }) # => array of PoeWatch::League items
      # 
      # Returns an Array of class instances.
      def where(params)
        PoeWatch::Api.refresh!
        self.all.select do |element| 
          params.map do |k, v| 
          if v.is_a? Regexp
            !!element.send(k).match(v)
          else
            element.send(k) == v 
          end
          end.all?(TrueClass)
        end
      end

      # Public: Gets a specific item
      # You can pass regular expressions for string parameters. It will do a match.
      #
      # params - A hash of parameters. Eg: { name: /Metamorph/, hardcore: true }
      #
      # Examples
      #
      #  PoeWatch::League.find({ name: "Metamorph", hardcore: true }) # =>PoeWatch::League item
      # 
      # Returns an instance of the class.
      def find(params)
        PoeWatch::Api.refresh!
        self.all.find do |element| 
          params.map do |k, v| 
          if v.is_a? Regexp
            !!element.send(k).match(v)
          else
            element.send(k) == v 
          end
          end.all?(TrueClass)
        end
      end
    end

    # Public: Initialize a Poe Watch item.
    # It will automatically create instance variables, setters, getters for instance variables,
    # and question mark methods for variables with boolean values.
    # It is to note that any hash or array of hashes will be transformed into an OpenStruct.
    #
    # raw_data - An array of hash
    #
    # Returns an instance of the class.
    def initialize(raw_data) 
      raw_data.each do |k, v|
        key = snakify(k)
        if v.is_a?(Hash)
          value = OpenStruct.new(v) 
        elsif v.is_a?(Array) && v.first.is_a?(Hash)
          value = v.map { |arr_val| OpenStruct.new(arr_val) }
        else
          value = v
        end

        instance_variable_set("@#{key}", value)

        define_singleton_method key do
          instance_variable_get("@#{key}")
        end

        # If it is a boolean we also create a `key?` method`
        if [TrueClass, FalseClass].include?(value.class)
          define_singleton_method "#{key}?" do
            instance_variable_get("@#{key}")
          end
        end
      end
    end
  end
end
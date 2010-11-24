require 'rubygems'
require 'fileutils'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_group "Basic", "lib/xapian_db"
end

require File.dirname(__FILE__) + '/../lib/xapian_db'

# Test class for indexed objects
class IndexedObject
  
  attr_reader :id
  
  def initialize(id)
    @id = id
  end
  
end

# Test adapter 
class DemoAdapter

  def self.add_helper_methods_to(klass)

    klass.instance_eval do
      
      # This method must be implemented by all adapters. It must
      # return a string that uniquely identifies an object
      define_method(:xapian_id) do
        "#{self.class}-#{self.id}"
      end
    end

  end
  
end

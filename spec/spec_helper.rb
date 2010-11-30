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
        "a_unique_key_expression"
      end
    end

  end
  
end

# Test class for indexed datamapper objects; this class mimics some behaviour
# of datamapper and has methods to test the helper methods
class DatamapperObject
  
  class << self
    
    attr_reader :hooks
    
    # Simulate the after method of datamapper
    def after(action, &block)
      @hooks ||= {}
      @hooks["after_#{action}".to_sym] = block
    end
    
  end
  
  attr_reader :id, :name
  
  def initialize(id, name)
    @id, @name = id, name
  end

  def save
    instance_eval &self.class.hooks[:after_save]
  end  
  
  def destroy
    instance_eval &self.class.hooks[:after_destroy]
  end
  
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true
  config.before(:each) do
    XapianDb::DocumentBlueprint.default_adapter = XapianDb::Adapters::GenericAdapter
    XapianDb::Adapters::GenericAdapter.unique_key do
      "#{self.class}-#{self.id}"
    end
  end
end

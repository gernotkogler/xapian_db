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

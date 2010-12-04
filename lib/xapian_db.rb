require 'digest/sha1'
require 'rubygems'
require 'xapian'
require 'yaml'
require 'progressbar'

module XapianDb

  # Configure XapianDb
  def self.setup(&block)
    XapianDb::Config.setup(&block)
  end
  
  # Create a database. Overwrites an existing database on disk, if
  # option :in_memory is set to false.
  def self.create_db(options = {})
    if options[:path] 
      PersistentDatabase.new(:path => options[:path], :create => true) 
    else
      InMemoryDatabase.new
    end
  end

  # Open a database.
  def self.open_db(options = {})
    if options[:path] 
      PersistentDatabase.new(:path => options[:path], :create => false) 
    else
      InMemoryDatabase.new
    end
  end
  
  # Access he configured database
  def self.database
    XapianDb::Config.database
  end
  
  # Query the database
  def self.search(expression)
    XapianDb::Config.database.search(expression)
  end
  
end

require File.dirname(__FILE__) + '/xapian_db/config'
require File.dirname(__FILE__) + '/xapian_db/adapters/generic_adapter'
require File.dirname(__FILE__) + '/xapian_db/adapters/datamapper_adapter'
require File.dirname(__FILE__) + '/xapian_db/adapters/active_record_adapter'
require File.dirname(__FILE__) + '/xapian_db/index_writers/direct_writer'
require File.dirname(__FILE__) + '/xapian_db/database'
require File.dirname(__FILE__) + '/xapian_db/document_blueprint'
require File.dirname(__FILE__) + '/xapian_db/indexer'
require File.dirname(__FILE__) + '/xapian_db/query_parser'
require File.dirname(__FILE__) + '/xapian_db/resultset'

# Configure XapianDB if we are in a Rails app
require File.dirname(__FILE__) + '/xapian_db/railtie' if defined?(Rails)

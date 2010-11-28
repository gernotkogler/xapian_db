require 'digest/sha1'
require 'rubygems'
require 'xapian'

module XapianDb

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
  
end

require File.dirname(__FILE__) + '/xapian_db/adapters/datamapper_adapter'
require File.dirname(__FILE__) + '/xapian_db/database'
require File.dirname(__FILE__) + '/xapian_db/document_blueprint'
require File.dirname(__FILE__) + '/xapian_db/indexer'
require File.dirname(__FILE__) + '/xapian_db/query_parser'
require File.dirname(__FILE__) + '/xapian_db/resultset'

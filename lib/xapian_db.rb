# encoding: utf-8

require 'digest/sha1'
require 'xapian'
require 'yaml'
require 'progressbar'

# This is the top level module of xapian_db. It allows you to
# configure XapianDB, create / open databases and perform
# searches.

# @author Gernot Kogler

module XapianDb

  # Global configuration for XapianDb. See {XapianDb::Config.setup}
  # for available options
  def self.setup(&block)
    XapianDb::Config.setup(&block)
  end

  # Create a database
  # @param [Hash] options
  # @option options [String] :path A path to the file system. If no path is
  #   given, creates an in memory database. <b>Overwrites an existing database!</b>
  # @return [XapianDb::Database]
  def self.create_db(options = {})
    if options[:path]
      PersistentDatabase.new(:path => options[:path], :create => true)
    else
      InMemoryDatabase.new
    end
  end

  # Open a database
  # @param [Hash] options
  # @option options [String] :path A path to the file system. If no path is
  #   given, creates an in memory database. If a path is given, then database
  #   must exist.
  # @return [XapianDb::Database]
  def self.open_db(options = {})
    if options[:path]
      PersistentDatabase.new(:path => options[:path], :create => false)
    else
      InMemoryDatabase.new
    end
  end

  # Access the configured database. See {XapianDb::Config.setup}
  # for instructions on how to configure a database
  # @return [XapianDb::Database]
  def self.database
    XapianDb::Config.database
  end

  # Query the configured database.
  # See {XapianDb::Database#search} for options
  # @return [XapianDb::Resultset]
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

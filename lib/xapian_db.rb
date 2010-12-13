# encoding: utf-8

# This is the top level module of xapian_db. It allows you to
# configure XapianDB, create / open databases and perform
# searches.

# @author Gernot Kogler

require 'xapian'
require 'yaml'

module XapianDb

  # Supported languages
  LANGUAGE_MAP = {:da => :danish,
                  :nl => :dutch,
                  :en => :english,
                  :fi => :finnish,
                  :fr => :french,
                  :de => :german2, # Normalises umlauts and ß
                  :hu => :hungarian,
                  :it => :italian,
                  :nb => :norwegian,
                  :nn => :norwegian,
                  :no => :norwegian,
                  :pt => :portuguese,
                  :ro => :romanian,
                  :ru => :russian,
                  :es => :spanish,
                  :sv => :swedish,
                  :tr => :turkish}

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

do_not_require = %w(update_stopwords.rb railtie.rb)
files = Dir.glob("#{File.dirname(__FILE__)}/**/*.rb").reject{|path| do_not_require.include?(File.basename(path))}
files.each {|file| require file}

# Configure XapianDB if we are in a Rails app
require File.dirname(__FILE__) + '/xapian_db/railtie' if defined?(Rails)

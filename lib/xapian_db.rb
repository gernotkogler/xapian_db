# encoding: utf-8

# This is the top level module of xapian_db. It allows you to
# configure XapianDB, create / open databases and perform
# searches.

# @author Gernot Kogler

require 'xapian'
require 'json'

do_not_require = %w(update_stopwords railtie base_adapter generic_adapter active_record_adapter datamapper_adapter
                    beanstalk_writer resque_writer sidekiq_writer utilities install_generator datamapper)
files = Dir.glob("#{File.dirname(__FILE__)}/**/*.rb").reject{|path| do_not_require.include?(File.basename(path, ".rb"))}
# Require these first
require "#{File.dirname(__FILE__)}/xapian_db/utilities"
require "#{File.dirname(__FILE__)}/xapian_db/adapters/base_adapter"
files.each {|file| require file}

# Configure XapianDB if we are in a Rails app
require File.dirname(__FILE__) + '/xapian_db/railtie' if defined?(Rails)

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
    @writer = XapianDb::Config.writer
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
  def self.search(expression, options={})
    order = options.delete :order
    if order
      attr_names             = [order].flatten
      undefined_attrs        = attr_names - XapianDb::DocumentBlueprint.attributes
      raise ArgumentError.new "invalid order clause: attributes #{undefined_attrs.inspect} are not defined" unless undefined_attrs.empty?
      options[:sort_indices] = attr_names.map {|attr_name| XapianDb::DocumentBlueprint.value_number_for(attr_name) }
    end
    XapianDb::Config.database.search(expression, options)
  end

  # Get facets from the configured database.
  # See {XapianDb::Database#facets} for options
  # @return [Hash<Class, Integer>] A hash containing the classes and the hits per class
  def self.facets(attribute, expression)
    XapianDb::Config.database.facets attribute, expression
  end

  # Update an object in the index
  # @param [Object] obj An instance of a class with a blueprint configuration
  def self.index(obj, commit=true, changed_attrs: [])
    writer = Thread.current[:xapian_db_block_writer] || XapianDb::Config.writer
    writer.index obj, commit, changed_attrs: changed_attrs
  end

  # Remove a document from the index
  # @param [String] xapian_id The document id
  def self.delete_doc_with(xapian_id, commit=true)
    writer = Thread.current[:xapian_db_block_writer] || XapianDb::Config.writer
    writer.delete_doc_with xapian_id, commit
  end

  # Update or delete a xapian document belonging to an object depending on the ignore_if logic(if present)
  # @param [Object] object An instance of a class with a blueprint configuration
  def self.reindex(object, commit=true, changed_attrs: [])
    writer = Thread.current[:xapian_db_block_writer] || XapianDb::Config.writer
    blueprint = XapianDb::DocumentBlueprint.blueprint_for object.class.name
    if blueprint.should_index?(object)
      writer.index object, commit, changed_attrs: changed_attrs
    else
      writer.delete_doc_with object.xapian_id, commit
    end
  end

  # Reindex all objects of a given class
  # @param [Class] klass The class to reindex
  # @param [Hash] options Options for reindexing
  # @option options [Boolean] :verbose (false) Should the reindexing give status informations?
  def self.reindex_class(klass, options={})
    XapianDb::Config.writer.reindex_class klass, options
  end

  # Rebuild the xapian index for all configured blueprints
  # @param [Hash] options Options for reindexing
  # @option options [Boolean] :verbose (false) Should the reindexing give status informations?
  # @return [Boolean] Did we reindex anything?
  def self.rebuild_xapian_index(options={})
    configured_classes = XapianDb::DocumentBlueprint.configured_classes
    return false unless configured_classes.size > 0
    configured_classes.each do |klass|
      if klass.respond_to?(:rebuild_xapian_index)
        XapianDb::Config.writer.reindex_class(klass, options)
      end
    end
    true
  end

  # Execute a block as a transaction
  def self.transaction(&block)
    writer = XapianDb::IndexWriters::TransactionalWriter.new
    execute_block :writer => writer, :error_message => "error in XapianDb transaction block, transaction aborted" do
      block.call
      writer.commit_using XapianDb::Config.writer
    end
  end

  # Execute a block and do not update the index
  def self.auto_indexing_disabled(&block)
    execute_block :writer => XapianDb::IndexWriters::NoOpWriter do
      block.call
    end

  end

  # execute a block of code with a given writer and handle errors
  # @param [Hash] opts Options
  # @option opts [Object] :writer An index writer
  # @option opts [String] :error_message the error message to log if an error occurs
  def self.execute_block(opts, &block)
    Thread.current[:xapian_db_block_writer] = opts[:writer]
    begin
      block.call
    rescue Exception => ex
      if opts[:error_message]
        if defined?(Rails)
          Rails.logger.error opts[:error_message]
        else
          puts opts[:error_message]
        end
      end
      raise
    ensure
      # release the block writer
      Thread.current[:xapian_db_block_writer] = nil
    end
  end
end

# -*- coding: utf-8 -*-

module XapianDb

  # Global configuration for XapianDb
  # @example A typical configuration might look like this:
  #   XapianDb::Config.setup do |config|
  #     config.adapter  :active_record
  #     config.writer   :direct
  #     config.database "db/xapian_db"
  #   end
  # @author Gernot Kogler
  class Config

    include XapianDb::Utilities

    # ---------------------------------------------------------------------------------
    # Singleton methods
    # ---------------------------------------------------------------------------------
    class << self

      # Configure global options for XapianDb.
      # Availabe options:
      # - adapter (see {XapianDb::Config#adapter})
      # - writer (see {XapianDb::Config#writer})
      # - database (see {XapianDb::Config#database})
      # - language (see {XapianDb::Config#language})
      # In a Rails app, you can configure XapianDb using a config file. See the README for the details
      def setup(&block)
        @config ||= Config.new
        yield @config if block_given?
      end

      # Install delegates for the config instance variables
      [:database, :adapter, :writer, :stemmer, :stopper].each do |attr|
        define_method attr do
          @config.nil? ? nil : @config.instance_variable_get("@_#{attr}")
        end
      end

      # The beanstalk daemon url
      define_method :beanstalk_daemon_url do
        default_url = "localhost:11300"
        return default_url if @config.nil?
        @config.instance_variable_get("@_beanstalk_daemon_url") || default_url
      end

      def resque_queue
        @config.instance_variable_get("@_resque_queue") || 'xapian_db'
      end
    end

    # ---------------------------------------------------------------------------------
    # DSL methods
    # ---------------------------------------------------------------------------------

    attr_reader :_database, :_adapter, :_writer, :_beanstalk_daemon, :_resque_queue, :_stemmer, :_stopper

    # Set the global database to use
    # @param [String] path The path to the database. Either apply a file sytem path or :memory
    #   for an in memory database
    def database(path)

      # If the current database is a persistent database, we must release the
      # database and run the garbage collector to remove the write lock
      if @_database.is_a?(XapianDb::PersistentDatabase)
        @_database = nil
        GC.start
      end

      if path.to_sym == :memory
        @_database = XapianDb.create_db
      else
        begin
          @_database = XapianDb.open_db :path => path
        rescue IOError
          @_database = XapianDb.create_db :path => path
        end
      end
    end

    # Set the adapter
    # @param [Symbol] type The adapter type; the following adapters are available:
    #   - :generic ({XapianDb::Adapters::GenericAdapter})
    #   - :active_record ({XapianDb::Adapters::ActiveRecordAdapter})
    #   - :datamapper ({XapianDb::Adapters::DatamapperAdapter})
    def adapter(type)
      # We try to guess the adapter name
      @_adapter = XapianDb::Adapters.const_get("#{camelize(type.to_s)}Adapter")
    end

    # Set the index writer
    # @param [Symbol] type The writer type; the following adapters are available:
    #   - :direct ({XapianDb::IndexWriters::DirectWriter})
    #   - :beanstalk ({XapianDb::IndexWriters::BeanstalkWriter})
    #   - :resque ({XapianDb::IndexWriters::ResqueWriter})
    def writer(type)
      # We try to guess the writer name
      begin
        require File.dirname(__FILE__) + "/index_writers/#{type}_writer"
        @_writer = XapianDb::IndexWriters.const_get("#{camelize(type.to_s)}Writer")
      rescue LoadError
        puts "XapianDb: cannot load #{type} writer; see README for supported writers and how to install neccessary queue infrastructure"
        raise
      end
    end

    # Set the url and port of the beanstalk daemon
    # @param [Symbol] url The url of the beanstalk daemon; defaults to localhost:11300
    def beanstalk_daemon_url(url)
      @_beanstalk_daemon_url = url
    end

    # Set the name of the resque queue
    # @param [String] name The name of the resque queue
    def resque_queue(name)
      @_resque_queue = name
    end

    # Set the language.
    # @param [Symbol] lang The language; apply the two letter ISO639 code for the language
    # @example
    #   XapianDb::Config.setup do |config|
    #     config.language :de
    #   end
    # see {LANGUAGE_MAP} for supported languages
    def language(lang)
      lang ||= :none
      @_stemmer = XapianDb::Repositories::Stemmer.stemmer_for lang
      @_stopper = lang == :none ? nil : XapianDb::Repositories::Stopper.stopper_for(lang)
    end

  end

end

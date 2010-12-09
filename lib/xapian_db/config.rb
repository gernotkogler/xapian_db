# encoding: utf-8

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

    # ---------------------------------------------------------------------------------   
    # Singleton methods
    # ---------------------------------------------------------------------------------   
    class << self

      # Configure global options for XapianDb.
      # Availabe options:
      # - adapter. Set the adapter to use. The following adapters are available:
      #   - :generic ({XapianDb::Adapters::GenericAdapter})
      #   - :active_record ({XapianDb::Adapters::ActiveRecordAdapter})
      #   - :datamapper ({XapianDb::Adapters::DatamapperAdapter})
      #   To use XapianDb without Rails, you might want to use the generic adapter.
      #   If you are using ActiveRecord or Datamapper, configure the appropriate
      #   Adapter.
      # - writer. Right now there is only one writer available: :direct ({XapianDb::IndexWriters::DirectWriter}).
      #   More advanced writers will be availabe in future releases
      # - database. For an in memory database, use :memory. For a persistent database,
      #   apply a path to the file system.
      # In a Rails app, you can configure XapianDb using a config file. See the README for the details
      def setup(&block)
        @config ||= Config.new
        yield @config if block_given?
      end
      
      # Install delegates for the config instance variables
      [:database, :adapter, :writer].each do |attr|
        define_method attr do
          @config.nil? ? nil : @config.instance_variable_get("@_#{attr}")
        end
      end                
    end  

    # ---------------------------------------------------------------------------------   
    # DSL methods
    # ---------------------------------------------------------------------------------   
    
    #
    attr_reader :_database, :_adapter, :_writer 
    
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
        if File.exist?(path)
          @_database = XapianDb.open_db :path => path
        else
          # Database does not exist; create it
          @_database = XapianDb.create_db :path => path
        end
      end
    end
    
    # Define the adapter to use; the following adapters are available:
    # - :generic ({XapianDb::Adapters::GenericAdapter})
    # - :active_record ({XapianDb::Adapters::ActiveRecordAdapter})
    # - :datamapper ({XapianDb::Adapters::DatamapperAdapter})
    def adapter(type)
      # We try to guess the adapter name
      @_adapter = XapianDb::Adapters.const_get("#{camelize(type.to_s)}Adapter")
    end

    # Define the writer to use; the following adapters are available:
    # - :direct ({XapianDb::IndexWriters::DirectWriter})
    # More to come in a future release
    def writer(type)
      # We try to guess the writer name
      @_writer = XapianDb::IndexWriters.const_get("#{camelize(type.to_s)}Writer")
    end
    
    private
    
    # TODO: move this to a helper module
    def camelize(string)
      string.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
    end
    
  end
  
end
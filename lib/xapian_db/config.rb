# encoding: utf-8

# Global configuration for XapianDb
# @author Gernot Kogler

module XapianDb
  
  class Config

    # ---------------------------------------------------------------------------------   
    # Singleton methods
    # ---------------------------------------------------------------------------------   
    class << self

      def setup(&block)
        @config ||= Config.new
        yield @config if block_given?
      end
      
      def database
        @config._database
      end
      
      def adapter
        @config._adapter
      end

      def writer
        @config._writer
      end
                
    end  

    # ---------------------------------------------------------------------------------   
    # DSL methods
    # ---------------------------------------------------------------------------------   
    attr_reader :_database, :_adapter, :_writer
    
    # Set the database; either pass a path to the file system or
    # the symbolic name "memory"
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
    # - :generic
    # - :active_record
    # - :datamapper
    def adapter(type)
      # We try to guess the adapter name
      @_adapter = XapianDb::Adapters.const_get("#{camelize(type.to_s)}Adapter")
    end

    # Define the writer to use; the following adapters are available:
    # - :direct
    # More to come in a future release :-)
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
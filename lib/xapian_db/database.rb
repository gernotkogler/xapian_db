# encoding: utf-8

# Singleton class representing a Xapian database.
# @author Gernot Kogler

module XapianDb

  # Base class for a Xapian database.    
  class Database
    
    class << self
    
      # Create a database. Overwrites an existing database on disk, if
      # option :in_memory is set to false.
      def create(options = {})
        @options = {:in_memory => true}.merge(options)
        @options[:in_memory] ? create_in_memory : create_persistent(@options[:path])
      end
      
      private

      # Create a new in memory database  
      def create_in_memory
        InMemoryDatabase.new
      end
      
    end
    
  end
  
  class InMemoryDatabase < Database

    def reader
      Xapian::Database.new
    end
    
    def writer
      @writer ||= Xapian::inmemory_open
    end
    
  end

  class PersistentDatabase < Database
  end
  
end
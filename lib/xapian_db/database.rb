# encoding: utf-8

# Singleton class representing a Xapian database.
# @author Gernot Kogler

module XapianDb

  # Base class for a Xapian database.    
  class Database
    attr_reader :reader    
    
  end
  
  # In Memory database
  class InMemoryDatabase < Database

    def initialize
      @reader = Xapian::Database.new
    end
    
    def writer
      @writer ||= Xapian::inmemory_open
    end
    
  end

  # Persistent database on disk
  class PersistentDatabase < Database
        
    def initialize(options)
      @path    = options[:path]
      @db_flag = options[:create] ? Xapian::DB_CREATE_OR_OVERWRITE : Xapian::DB_OPEN
      if options[:create]
        @writer = Xapian::WritableDatabase.new(@path, @db_flag)
      end
      @reader = Xapian::Database.new(@path)
    end
    
    def writer
      @writer ||= Xapian::WritableDatabase.new(@path, @db_flag)
    end
    
  end
  
end
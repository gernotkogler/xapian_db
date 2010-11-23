# encoding: utf-8

# Singleton class representing a Xapian database.
# @author Gernot Kogler

module XapianDb

  # Base class for a Xapian database.    
  class Database
    attr_reader :writer
  end
  
  # In Memory database
  class InMemoryDatabase < Database

    def initialize
      @writer = Xapian::inmemory_open
    end
    
    # Access to a database reader; for now we always create
    # a new Database instance. Might be reconsidered when we
    # need some optimizations
    def reader
      Xapian::Database.new
    end
    
  end

  # Persistent database on disk
  class PersistentDatabase < Database
        
    def initialize(options)
      @path   = options[:path]
      db_flag = options[:create] ? Xapian::DB_CREATE_OR_OVERWRITE : Xapian::DB_OPEN
      @writer = Xapian::WritableDatabase.new(@path, db_flag)
    end
    
    # Access to a database reader; for now we always create
    # a new Database instance. Might be reconsidered when we
    # need some optimizations
    def reader
      Xapian::Database.new(@path)
    end

  end
  
end
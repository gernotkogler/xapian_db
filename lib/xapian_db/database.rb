# encoding: utf-8

# Singleton class representing a Xapian database.
# @author Gernot Kogler

module XapianDb

  # Base class for a Xapian database.    
  class Database
    attr_reader :reader    
    
    # Size of the database (number of docs)
    def size
      reader.doccount
    end
    
    # Store a Xapian document
    def store_doc(doc)
      # We always replace; Xapian adds the document automatically if
      # it is not found
      writer.replace_document("Q#{doc.data}", doc)
    end

    # Delete a document by a unique term; this method is used by the
    # orm adapters
    def delete_doc_with_unique_term(term)
      writer.delete_document("Q#{term}")
      true
    end

    # Delete all docs of a specific class 
    def delete_docs_of_class(klass)
      writer.delete_document("C#{klass}")
      true
    end
       
    # Perform a search
    def search(expression)
      @query_parser ||= QueryParser.new(self)
      query = @query_parser.parse(expression)
      enquiry = Xapian::Enquire.new(reader)
      enquiry.query = query
      Resultset.new(enquiry)
    end
           
  end
  
  # In Memory database
  class InMemoryDatabase < Database

    def initialize
      @writer ||= Xapian::inmemory_open
      @reader = @writer
    end
    
    def writer
      @writer
    end

    # Commit all pending changes 
    def commit
      # Nothing to do for an in memory database
    end
    
  end

  # Persistent database on disk
  class PersistentDatabase < Database
        
    def initialize(options)
      @path    = options[:path]
      @db_flag = options[:create] ? Xapian::DB_CREATE_OR_OVERWRITE : Xapian::DB_OPEN
      if options[:create]
        # make sure the path exists; Xapian will not create the necessary directories 
        FileUtils.makedirs @path
        @writer = Xapian::WritableDatabase.new(@path, @db_flag)
      end
      @reader = Xapian::Database.new(@path)
    end
    
    # The writer is instantiated layzily to avoid a permanent write lock on the database
    def writer
      @writer ||= Xapian::WritableDatabase.new(@path, @db_flag)
    end
   
    # Commit all pending changes 
    def commit
      writer.commit
      reader.reopen
    end
    
  end
  
end
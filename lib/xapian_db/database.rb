# encoding: utf-8

# @author Gernot Kogler

module XapianDb

  # Base class for a Xapian database
  class Database

    # A readable xapian database (see http://xapian.org/docs/apidoc/html/classXapian_1_1Database.html)
    attr_reader :reader

    # Size of the database (number of docs)
    # @return [Integer] The number of docs in the database
    def size
      reader.doccount
    end

    # Store a Xapian document
    # @param [Xapian::Document] doc A Xapian document (see http://xapian.org/docs/sourcedoc/html/classXapian_1_1Document.html).
    #   While you can pass any valid xapian document, you might want to use the {XapianDb::Indexer} to build a xapian doc
    def store_doc(doc)
      # We always replace; Xapian adds the document automatically if
      # it is not found
      writer.replace_document("Q#{doc.data}", doc)
    end

    # Delete a document identified by a unique term; this method is used by the
    # orm adapters
    # @param [String] term A term that uniquely identifies a document
    def delete_doc_with_unique_term(term)
      writer.delete_document("Q#{term}")
      true
    end

    # Delete all docs of a specific class
    # @param [Class] klass A class that has a {XapianDb::DocumentBlueprint} configuration
    def delete_docs_of_class(klass)
      writer.delete_document("C#{klass}")
      true
    end

    # Perform a search
    # @param [String] expression A valid search expression.
    # @param [Hash] options
    # @option options [Integer] :per_page (10) How many docs per page?
    # @example Simple Query
    #   resultset = db.search("foo")
    # @example Wildcard Query
    #   resultset = db.search("fo*")
    # @example Boolean Query
    #   resultset = db.search("foo or baz")
    # @example Field Query
    #   resultset = db.search("name:foo")
    # @return [XapianDb::Resultset] The resultset
    def search(expression, options={})
      opts          = {:per_page => 10}.merge(options)
      @query_parser ||= QueryParser.new(self)
      query         = @query_parser.parse(expression)
      enquiry       = Xapian::Enquire.new(reader)
      enquiry.query = query
      Resultset.new(enquiry, opts)
    end

  end

  # In Memory database
  class InMemoryDatabase < Database

    def initialize
      @writer ||= Xapian::inmemory_open
      @reader = @writer
    end

    # Get the writer to write to the database
    # @return [Xapian::WritableDatabase] A xapian database that is writable (see http://xapian.org/docs/apidoc/html/classXapian_1_1WritableDatabase.html)
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

    # Constructor
    # @param [Hash] options Options for the persistent database
    # @option options [String] :path A path to the file system
    # @option options [Boolean] :create Should the database be created? <b>Will overwrite an existing database if true!</b>
    # @example Force the creation of a database. Will overwrite an existing database
    #   db = XapianDb::PersistentDatabase.new(:path => "/tmp/mydb", :create => true)
    # @example Open an existing database. The database must exist
    #   db = XapianDb::PersistentDatabase.new(:path => "/tmp/mydb", :create => false)
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

    # Get the readable instance of the database. On each access this method reopens the readable database
    # to make sure you get the latest changes to the index
    # @return [Xapian::Database] A readable xapian database (see http://xapian.org/docs/apidoc/html/classXapian_1_1Database.html)
    def reader
      # Always reopen the readable database so we get live index data
      # TODO: make this configurable
      @reader.reopen
      @reader
    end

    # The writer is instantiated layzily to avoid a permanent write lock on the database. Please note that
    # you will get locking exceptions if you open the same database multiple times and access the writer
    # in more than one instance!
    # @return [Xapian::WritableDatabase] A xapian database that is writable (see http://xapian.org/docs/apidoc/html/classXapian_1_1WritableDatabase.html)
    def writer
      @writer ||= Xapian::WritableDatabase.new(@path, @db_flag)
    end

    # Commit all pending changes
    def commit
      writer.commit
    end

  end

end
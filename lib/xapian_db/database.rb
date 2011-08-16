# encoding: utf-8

# @author Gernot Kogler

module XapianDb

  # Base class for a Xapian database
  class Database

    include XapianDb::Utilities

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
    # @option options [Integer] :per_page How many docs per page?
    # @option options [Array<Integer>] :sort_indices (nil) An array of attribute indices to sort by. This
    #   option is used internally by the search method implemented on configured classes. Do not use it
    #   directly unless you know what you do
    # @option options [Boolean] :sort_decending (false) Reverse the sort order?
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
      opts          = {:sort_decending => false}.merge(options)
      @query_parser ||= QueryParser.new(self)
      query         = @query_parser.parse(expression)

      # If we do not have a valid query we return an empty result set
      return Resultset.new(nil, opts) unless query

      start = Time.now

      enquiry        = Xapian::Enquire.new(reader)
      enquiry.query  = query
      sort_indices   = opts.delete :sort_indices
      sort_decending = opts.delete :sort_decending

      if sort_indices
        raise ArgumentError.new("Sorting is available for class scoped searches only") unless expression =~ /^indexed_class:/
        sorter = Xapian::MultiValueSorter.new

        sort_indices.each do |index|
          sorter.add(index, sort_decending)
        end
        enquiry.set_sort_by_key_then_relevance(sorter)
      end

      opts[:spelling_suggestion] = @query_parser.spelling_suggestion
      opts[:db_size]             = self.size
      result = Resultset.new(enquiry, opts)

      Rails.logger.debug "XapianDb search (#{(Time.now - start) * 1000}ms) #{expression}" if defined?(Rails)
      result
    end

    # Find documents that are similar to one or more reference documents. It is basically
    # the implementation of this suggestion: http://trac.xapian.org/wiki/FAQ/FindSimilar
    # @param [Array<Xapian::Document> or Xapian::Document] docs One or more reference docs
    # @return [XapianDb::Resultset] The resultset
    def find_similar_to(docs)
      docs = [docs].flatten
      reference = Xapian::RSet.new
      docs.each { |doc| reference.add_document doc.docid }
      relevant_terms = Xapian::Enquire.new(reader).eset(40, reference).terms.map {|e| e.name }
      query          = Xapian::Query.new Xapian::Query::OP_OR, relevant_terms
      enquiry        = Xapian::Enquire.new(reader)
      enquiry.query  = query
      Resultset.new(enquiry, :db_size => self.size)
    end

    # A very simple implementation of facets limited to the class facets.
    # @param [String] expression A valid search expression (see {#search} for examples).
    # @return [Hash<Class, Integer>] A hash containing the classes and the hits per class
    def facets(expression)
      @query_parser        ||= QueryParser.new(self)
      query                = @query_parser.parse(expression)
      enquiry              = Xapian::Enquire.new(reader)
      enquiry.query        = query
      enquiry.collapse_key = 0 # Value 0 always contains the class name
      facets = {}
      enquiry.mset(0, self.size).matches.each do |match|
        class_name = match.document.values[0].value
        # We must add 1 to the collapse_count since collapse_count means
        # "how many other matches are there?"
        facets[constantize class_name] = match.collapse_count + 1
      end
      facets
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
# encoding: utf-8

module XapianDb

  # The indexer creates a Xapian::Document from an object. They object must be an instance
  # of a class that has a blueprint configuration.
  # @author Gernot Kogler
  class Indexer

    # Constructor
    # @param [XapianDb::Database] database The database to use (needed to build a spelling index)
    # @param [XapianDb::DocumentBlueprint] document_blueprint The blueprint to use
    def initialize(database, document_blueprint)
      @database, @document_blueprint = database, document_blueprint
    end

    # Build the document for an object. The object must respond to 'xapian_id'.
    # The configured adapter should implement this method.
    # @return [Xapian::Document] The xapian document (see http://xapian.org/docs/sourcedoc/html/classXapian_1_1Document.html)
    def build_document_for(obj)
      @obj = obj
      @blueprint = DocumentBlueprint.blueprint_for(@obj.class)
      @xapian_doc = Xapian::Document.new
      @xapian_doc.data = @obj.xapian_id
      store_fields
      index_text
      @xapian_doc
    end

    private

    # Store all configured fields
    def store_fields

      # We store the class name of the object at position 0
      @xapian_doc.add_value(0, @obj.class.name)

      pos = 1
      @blueprint.attributes.each do |attribute, options|
        value = @obj.send(attribute)
        @xapian_doc.add_value(pos, value.to_yaml)
        pos += 1
      end
    end

    # Index all configured text methods
    def index_text
      setup_language_helpers
      term_generator = Xapian::TermGenerator.new
      term_generator.database = @database.writer
      term_generator.document = @xapian_doc
      if @stemmer
        term_generator.stemmer  = @stemmer
        term_generator.stopper  = @stopper unless @stopper.nil?
        # Enable the creation of a spelling index if the database is not in memory
        if @database.is_a? XapianDb::PersistentDatabase
          term_generator.set_flags Xapian::TermGenerator::FLAG_SPELLING if @database.is_a? XapianDb::PersistentDatabase
        end
      end

      # Always index the class and the primary key
      @xapian_doc.add_term("C#{@obj.class}")
      @xapian_doc.add_term("Q#{@obj.xapian_id}")

      @blueprint.indexed_methods.each do |method, options|
        value = @obj.send(method)
        unless value.nil?
          values = value.is_a?(Array) ? value : [value]
          values.each do |value|
            # Add value with field name
            term_generator.index_text(value.to_s.downcase, options.weight, "X#{method.upcase}")
            # Add value without field name
            term_generator.index_text(value.to_s.downcase)
          end
        end
      end
    end

    private

    # Configure the stemmer and stopper to use
    def setup_language_helpers
      # Do we have a language config on the blueprint?
      if @blueprint.lang_method
        lang = @obj.send(@blueprint.lang_method)
        if lang && LANGUAGE_MAP.has_key?(lang.to_sym)
          @stemmer = XapianDb::Repositories::Stemmer.stemmer_for lang.to_sym
          @stopper = XapianDb::Repositories::Stopper.stopper_for lang.to_sym
          return
        end
      end

      # Use the global config
      @stemmer = XapianDb::Config.stemmer
      @stopper = XapianDb::Config.stopper

    end

  end

end
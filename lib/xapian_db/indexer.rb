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
      @blueprint = DocumentBlueprint.blueprint_for(@obj.class.name)
      @xapian_doc = Xapian::Document.new
      @xapian_doc.data = @obj.xapian_id
      store_fields
      index_text
      @xapian_doc
    end

    private

    # Store all configured fields
    def store_fields

      # class name of the object goes to position 0
      @xapian_doc.add_value 0, @obj.class.name
      # natural sort order goes to position 1
      if @blueprint._natural_sort_order.is_a? Proc
        sort_value = @obj.instance_eval &@blueprint._natural_sort_order
      else
        sort_value = @obj.send @blueprint._natural_sort_order
      end
      @xapian_doc.add_value 1, sort_value.to_s

      @blueprint.attribute_names.each do |attribute|
        block = @blueprint.block_for_attribute attribute
        if block
          value = @obj.instance_eval &block
        else
          value = @obj.send attribute
        end

        codec          = XapianDb::TypeCodec.codec_for @blueprint.type_map[attribute]
        encoded_string = codec.encode value
        @xapian_doc.add_value DocumentBlueprint.value_number_for(attribute), encoded_string unless encoded_string.nil?
      end
    end

    # Index all configured text methods
    def index_text
      term_generator = Xapian::TermGenerator.new
      term_generator.database = @database.writer
      term_generator.document = @xapian_doc
      if XapianDb::Config.stemmer
        term_generator.stemmer  = XapianDb::Config.stemmer
        term_generator.stopper  = XapianDb::Config.stopper if XapianDb::Config.stopper
        # Enable the creation of a spelling dictionary if the database is not in memory
        term_generator.set_flags Xapian::TermGenerator::FLAG_SPELLING if @database.is_a? XapianDb::PersistentDatabase
      end

      # Index the primary key as a unique term
      @xapian_doc.add_term("Q#{@obj.xapian_id}")

      # Index the class with the field name
      term_generator.index_text("#{@obj.class}".downcase, 1, "XINDEXED_CLASS")
      @xapian_doc.add_term("C#{@obj.class}")

      @blueprint.indexed_method_names.each do |method|
        options = @blueprint.options_for_indexed_method method
        if options.block
          obj = @obj.instance_eval(&options.block)
        else
          obj = @obj.send(method)
        end
        unless obj.nil?
          values = get_values_to_index_from obj
          values.each do |value|
            terms = value.to_s.downcase
            terms = split(terms) if XapianDb::Config.term_splitter_count > 0 && !options.no_split
            # Add value with field name
            term_generator.index_text(terms, options.weight, "X#{method.upcase}") if options.prefixed
            # Add value without field name
            term_generator.index_text(terms, options.weight)
          end
        end
      end

      terms_to_ignore = @xapian_doc.terms.select{ |term| term.term.length < XapianDb::Config.term_min_length }
      terms_to_ignore.each { |term| @xapian_doc.remove_term term.term }
    end

    # Get the values to index from an object
    def get_values_to_index_from(obj)

      # if it's an array, we collect the values for its elements recursive
      if obj.is_a? Array
        return obj.map { |element| get_values_to_index_from element }.flatten.compact
      end

      # if the object responds to attributes and attributes is a hash,
      # we use the attributes values (works well for active_record and datamapper objects)
      return obj.attributes.values.compact if obj.respond_to?(:attributes) && obj.attributes.is_a?(Hash)

      # The object is unkown and will be indexed by its to_s method; if to_s retruns nil, we
      # will not index it
      obj.to_s.nil? ? [] : [obj]
    end

    private

    def split(terms)
      splitted_terms = []
      terms.split(" ").each do |term|
        (1..XapianDb::Config.term_splitter_count).each { |i| splitted_terms << term[0...i] }
        splitted_terms << term
      end
      splitted_terms.join " "
    end

  end
end

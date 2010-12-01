# encoding: utf-8

# The indexer creates a Xapian::Document from a configured object
# @author Gernot Kogler

module XapianDb
  
  class Indexer
    
    def initialize(document_blueprint)
      @document_blueprint = document_blueprint
    end
    
    # Build the doc for an object. The object must respond to 'xapian_id'.
    # The configured adapter should implement this method.
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
      term_generator = Xapian::TermGenerator.new()
      term_generator.document = @xapian_doc
      # TODO: make this configurable globally and per document 
      # (retrieve the language from the object, if configured)
      stemmer = Xapian::Stem.new("english")
      term_generator.stemmer = stemmer
      # TODO: Configure and enable these features
      # tg.stopper = stopper if stopper
      # tg.stemmer = stemmer
      # tg.set_flags Xapian::TermGenerator::FLAG_SPELLING if db.spelling

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
    
  end
  
end
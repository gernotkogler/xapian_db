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
      pos = 0
      @blueprint.fields.each do |field, options|
        value = @obj.send(field).to_s
        @xapian_doc.add_value(pos, value)
        pos += 1
      end
    end
    
    # Index all configured text methods
    def index_text
      term_generator = Xapian::TermGenerator.new()
      # TODO: make this configurable globally and per document 
      # (retrieve the language from the object, if configured)
      stemmer = Xapian::Stem.new("english")
      term_generator.stemmer = stemmer
    end
    
  end
  
end
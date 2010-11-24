# encoding: utf-8

# The indexer creates a Xapian::Document from a XapianDb::Document 
# @author Gernot Kogler

module XapianDb
  
  class Indexer
    
    def initialize(document_blueprint)
      @document_blueprint = document_blueprint
    end
    
    def build_document_for(obj)

      indexer = Xapian::TermGenerator.new()
      stemmer = Xapian::Stem.new("english")
      indexer.stemmer = stemmer

      xapian_doc = Xapian::Document.new
      # xapian_doc.data = @document_blueprint.unique_identifier
      # 
      # pos = 0
      # @document.each do |field, value|
      #   xapian_doc.add_value(pos, value)
      #   pos += 1
      # end
      xapian_doc
        
    end
    
  end
  
end
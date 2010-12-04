# encoding: utf-8

# This writer writes changes directly to the open database. 
# Use the direct writer only for single process environments
# (one single rails app server, e.g. one mongrel).
# For multi process environemnts you should use a writer that
# processes index changes through a queue.
# @author Gernot Kogler

module XapianDb
  module IndexWriters
    
    class DirectWriter
      
      class << self
        
        # Update an object in the index
        def index(obj)
          blueprint = XapianDb::DocumentBlueprint.blueprint_for(obj.class)
          doc = blueprint.indexer.build_document_for(obj)
          XapianDb.database.store_doc(doc)
          XapianDb.database.commit
        end

        # Remove an object from the index
        def unindex(obj)
          XapianDb.database.delete_doc_with_unique_term(obj.xapian_id)
          XapianDb.database.commit
        end

        # Reindex all objects of a given class
        def reindex_class(klass)
          # First, delete all docs of this class
          XapianDb.database.delete_docs_of_class(klass)
          blueprint = XapianDb::DocumentBlueprint.blueprint_for(klass)
          obj_count = klass.count
          puts "Reindexing #{obj_count} objects..."
          pbar = ProgressBar.new("Status", obj_count)
          klass.all.each do |obj| 
            doc = blueprint.indexer.build_document_for(obj)
            XapianDb.database.store_doc(doc)
            pbar.inc
          end
          XapianDb.database.commit
        end
        
      end
      
    end 
    
  end
end
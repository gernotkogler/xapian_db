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

      BATCH_SIZE = 200
      class << self

        # Update an object in the index
        # @param [Object] obj An instance of a class with a blueprint configuration
        def index(obj)
          blueprint = XapianDb::DocumentBlueprint.blueprint_for(obj.class)
          indexer   = XapianDb::Indexer.new(XapianDb.database, blueprint)
          doc       = indexer.build_document_for(obj)
          XapianDb.database.store_doc(doc)
          XapianDb.database.commit
        end

        # Remove an object from the index
        # @param [String] xapian_id The document id of an object
        def delete_doc_with(xapian_id)
          XapianDb.database.delete_doc_with_unique_term xapian_id
          XapianDb.database.commit
        end

        # Reindex all objects of a given class
        # @param [Class] klass The class to reindex
        # @param [Hash] options Options for reindexing
        # @option options [Boolean] :verbose (false) Should the reindexing give status informations?
        def reindex_class(klass, options={})
          opts = {:verbose => false}.merge(options)
          XapianDb.database.delete_docs_of_class(klass)
          blueprint  = XapianDb::DocumentBlueprint.blueprint_for(klass)
          indexer    = XapianDb::Indexer.new(XapianDb.database, blueprint)
          base_query = blueprint._base_query || klass
          show_progressbar = false
          obj_count = base_query.count
          if opts[:verbose]
            show_progressbar = defined?(ProgressBar)
            puts "reindexing #{obj_count} objects of #{klass}..."
            pbar = ProgressBar.new("Status", obj_count) if show_progressbar
          end

          # Process the objects in batches to reduce the memory footprint
          nr_of_batches = (obj_count / BATCH_SIZE) + 1
          order_expression = "#{klass.name.tableize}.#{options[:primary_key]}"
          nr_of_batches.times do |batch|
            # raise "PK: #{options[:primary_key]}"
            base_query.all(:offset => batch * BATCH_SIZE, :limit => BATCH_SIZE, :order => order_expression).each do |obj|
              XapianDb.reindex obj
              pbar.inc if show_progressbar
            end
          end
          XapianDb.database.commit
          true
        end

      end
    end
  end
end
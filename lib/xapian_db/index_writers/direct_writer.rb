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

      BATCH_SIZE = 500

      class << self

        # Update an object in the index
        # @param [Object] object An instance of a class with a blueprint configuration
        def index(object, commit=true, changed_data: Hash.new)
          blueprint = XapianDb::DocumentBlueprint.blueprint_for(object.class.name)
          indexer   = XapianDb::Indexer.new(XapianDb.database, blueprint)
          doc       = indexer.build_document_for(object)
          XapianDb.database.store_doc(doc)
          XapianDb::DocumentBlueprint.dependencies_for(object.class.name, changed_data).each do |dependency|
            dependency.block.call(object).each{ |model| reindex model, commit, changed_data: changed_data }
          end
          XapianDb.database.commit if commit
        end

        # Remove an object from the index
        # @param [String] xapian_id The document id of an object
        def delete_doc_with(xapian_id, commit=true)
          XapianDb.database.delete_doc_with_unique_term xapian_id
          XapianDb.database.commit if commit
        end

        # Update or delete a xapian document belonging to an object depending on the ignore_if logic(if present)
        # @param [Object] object An instance of a class with a blueprint configuration
        def reindex(object, commit=true, changed_data: Hash.new)
          blueprint = XapianDb::DocumentBlueprint.blueprint_for object.class.name
          if blueprint.should_index?(object)
            index object, commit, changed_data: changed_data
          else
            delete_doc_with object.xapian_id, commit
          end
        end

        # Reindex all objects of a given class
        # @param [Class] klass The class to reindex
        # @param [Hash] options Options for reindexing
        # @option options [Boolean] :verbose (false) Should the reindexing give status informations?
        def reindex_class(klass, options={})
          opts = {:verbose => false}.merge(options)
          blueprint = XapianDb::DocumentBlueprint.blueprint_for klass.name
          primary_key = blueprint._adapter.primary_key_for(klass)
          XapianDb.database.delete_docs_of_class(klass)
          indexer    = XapianDb::Indexer.new(XapianDb.database, blueprint)
          if blueprint.lazy_base_query
            base_query = blueprint.lazy_base_query.call
          else
            base_query = klass
          end
          show_progressbar = false
          obj_count = base_query.count
          if opts[:verbose]
            show_progressbar = defined?(ProgressBar)
            puts "reindexing #{obj_count} objects of #{klass}..."
            pbar = ProgressBar.create(:title => "Status", :total => obj_count, :format => ' %t %e %B %p%%') if show_progressbar
          end

          # Process the objects in batches to reduce the memory footprint
          nr_of_batches = (obj_count / BATCH_SIZE) + 1
          nr_of_batches.times do |batch|
            base_query.offset(batch * BATCH_SIZE).limit(BATCH_SIZE).order(klass.order_condition(primary_key)).each do |obj|
              reindex obj, false
              pbar.increment if show_progressbar
            end
          end
          XapianDb.database.commit
          true
        end
      end
    end
  end
end

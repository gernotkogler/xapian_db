# encoding: utf-8

# This writer is a dummy writer that simply does nothing.
# @author Gernot Kogler

module XapianDb
  module IndexWriters

    class NoOpWriter

      # Update an object in the index
      # @param [Object] obj An instance of a class with a blueprint configuration
      def index(obj, commit=true); end

      # Remove an object from the index
      # @param [String] xapian_id The document id
      def delete_doc_with(xapian_id, commit=true); end

      # Reindex all objects of a given class
      # @param [Class] klass The class to reindex
      # @param [Hash] options Options for reindexing
      # @option options [Boolean] :verbose (false) Should the reindexing give status informations?
      def reindex_class(klass, options={})
        raise "rebuild_xapian_index is not supported inside a block with auto indexing disabled"
      end

    end
  end
end
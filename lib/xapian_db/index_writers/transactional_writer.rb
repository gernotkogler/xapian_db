# encoding: utf-8

# This writer collects index change requests but does not submit them immediately to the database.
# The index changes are applied when the commit method is called.
# This writer is intended for internal use only. Do not use it in a xapian configuration!
# @author Gernot Kogler

module XapianDb
  module IndexWriters

    class TransactionalWriter

      attr_reader :index_requests, :delete_requests

      # Constructor
      def initialize
        @index_requests  = []
        @delete_requests = []
      end

      # Update an object in the index
      # @param [Object] obj An instance of a class with a blueprint configuration
      def index(obj)
        @index_requests << obj
      end

      # Remove a document from the index
      # @param [String] xapian_id The document id
      def delete_doc_with(xapian_id)
        @delete_requests << xapian_id
      end

      # Reindex all objects of a given class
      # @param [Class] klass The class to reindex
      # @param [Hash] options Options for reindexing
      # @option options [Boolean] :verbose (false) Should the reindexing give status informations?
      def reindex_class(klass, options={})
        raise "rebuild_xapian_index is not supported in transactions"
      end

      # Commit all pending changes to the database
      # @param [DirectWriter, BeanstalkWriter] writer The writer to use
      def commit_using(writer)
        @index_requests.each { |obj| writer.index obj }
        @delete_requests.each { |xapian_id| writer.delete_doc_with xapian_id }
      end

    end

  end
end
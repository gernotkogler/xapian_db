# -*- coding: utf-8 -*-
# This writer uses resque to enqueue index jobs
# @author Michael Stämpfli

require 'resque'

module XapianDb
  module IndexWriters
    class ResqueWriter

      class << self

        # Update an object in the index
        # @param [Object] obj An instance of a class with a blueprint configuration
        def index(obj, commit=true)
          Resque.enqueue worker_class, :index, :class => obj.class.name, :id => obj.id
        end

        # Remove an object from the index
        # @param [String] xapian_id The document id
        def delete_doc_with(xapian_id, commit=true)
          Resque.enqueue worker_class, :delete_doc, :xapian_id => xapian_id
        end

        # Reindex all objects of a given class
        # @param [Class] klass The class to reindex
        def reindex_class(klass, options = {})
          Resque.enqueue worker_class, :reindex_class, :class => klass.name
        end

        def worker_class
          ResqueWorker
        end
        private :worker_class
      end

    end
  end
end

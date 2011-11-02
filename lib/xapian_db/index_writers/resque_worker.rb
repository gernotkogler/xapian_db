# -*- coding: utf-8 -*-
module XapianDb
  module IndexWriters
    # Worker to update the Xapian index; the worker will be called by resque
    # and uses the DirectWriter to do the real work
    # @author Michael Stämpfli
    class ResqueWorker

      extend XapianDb::Utilities

      APPROVED_TASKS = [:index, :delete_doc, :reindex_class]

      class << self
        def queue
          :xapian_db
        end

        def perform(task, options)
          send(task, options) if APPROVED_TASKS.include?(task.to_sym)
        end

        def index(options)
          klass = constantize options['class']
          obj   = klass.respond_to?('get') ? klass.get(options['id']) : klass.find(options['id'])
          DirectWriter.index obj
        end

        def delete_doc(options)
          DirectWriter.delete_doc_with options['xapian_id']
        end

        def reindex_class(options)
          klass = constantize options['class']
          DirectWriter.reindex_class klass, :verbose => false
        end
      end

    end
  end
end

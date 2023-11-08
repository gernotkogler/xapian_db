# -*- coding: utf-8 -*-
# This writer uses sidekiq to enqueue index jobs
# @author Michael Stämpfli and John Bradley

require 'sidekiq'

module XapianDb
  module IndexWriters
    class SidekiqWriter

      SidekiqWorker.class_eval do
        include Sidekiq::Worker
      end

      class << self

        # Update an object in the index
        # @param [Object] obj An instance of a class with a blueprint configuration

        def queue
          XapianDb::Config.sidekiq_queue
        end

        def index(obj, _commit= true, changed_attrs: [])
          Sidekiq::Client.enqueue_to(queue, worker_class, 'index',
                                     {
                                       class: obj.class.name,
                                       id: obj.id,
                                       changed_attrs: changed_attrs
                                     }.to_json)
        end

        # Remove an object from the index
        # @param [String] xapian_id The document id
        def delete_doc_with(xapian_id, _commit= true)
          Sidekiq::Client.enqueue_to(queue, worker_class, 'delete_doc', { xapian_id: xapian_id }.to_json)
        end

        # Reindex all objects of a given class
        # @param [Class] klass The class to reindex
        def reindex_class(klass, _options = {})
          Sidekiq::Client.enqueue_to(queue, worker_class, 'reindex_class', { class: klass.name }.to_json)
        end

        def worker_class
          SidekiqWorker
        end
        private :worker_class
      end
    end
  end
end

# -*- coding: utf-8 -*-
# This writer uses sidekiq to enqueue index jobs
# @author Michael Stämpfli and John Bradley

require 'sidekiq'

module XapianDb
  module IndexWriters
    class SidekiqWriter

      SidekiqWorker.class_eval do
        include Sidekiq::Worker

        sidekiq_options set_max_expansion: set_max_expansion
      end

      class << self
        def queue
          XapianDb::Config.sidekiq_queue
        end

        # Update an object in the index
        # @param [Object] obj An instance of a class with a blueprint configuration
        def index(obj, _commit= true, changed_attrs: [])
          Sidekiq::Client.push('queue' => queue,
                               'class' => worker_class,
                               'args' => ['index', { class: obj.class.name, id: obj.id, changed_attrs: changed_attrs }.to_json],
                               'retry' => sidekiq_retry)
        end

        # Remove an object from the index
        # @param [String] xapian_id The document id
        def delete_doc_with(xapian_id, _commit= true)
          Sidekiq::Client.push('queue' => queue,
                               'class' => worker_class,
                               'args' => ['delete_doc', { xapian_id: xapian_id }.to_json],
                               'retry' => sidekiq_retry)
        end

        # Reindex all objects of a given class
        # @param [Class] klass The class to reindex
        def reindex_class(klass, _options = {})
          Sidekiq::Client.push('queue' => queue,
                               'class' => worker_class,
                               'args' => ['reindex_class', { class: klass.name }.to_json],
                               'retry' => sidekiq_retry)
        end

        def set_max_expansion
          XapianDb::Config.set_max_expansion
        end

        def sidekiq_retry
          XapianDb::Config.sidekiq_retry
        end

        def worker_class
          SidekiqWorker
        end
        private :worker_class
      end
    end
  end
end

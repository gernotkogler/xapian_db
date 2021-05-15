# encoding: utf-8

module XapianDb
  module IndexWriters

    # Worker to update the Xapian index; the worker is used in the beanstalk worker script
    # and uses the DirectWriter to do the real work
    # @author Gernot Kogler
    class BeanstalkWorker

      include XapianDb::Utilities

      def index_task(options)
        klass = constantize options[:class]
        obj   = klass.respond_to?(:get) ? klass.get(options[:id]) : klass.find(options[:id])
        DirectWriter.index obj, options[:commit], changed_attrs: options[:changed_attrs]
      end

      def delete_doc_task(options)
        DirectWriter.delete_doc_with options[:xapian_id]
      end

      def reindex_class_task(options)
        klass = constantize options[:class]
        DirectWriter.reindex_class klass, :verbose => false
      end
    end
  end
end

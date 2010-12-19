# encoding: utf-8

module XapianDb
  module IndexWriters

    # Worker to update the Xapian index; the worker is used in the beanstalk worker rake task
    # and uses the DirectWriter to do the real work
    # @author Gernot Kogler
    class BeanstalkWorker

      def index_task(options)
        klass = Kernel.const_get options[:class]
        obj   = klass.respond_to?(:get) ? klass.get(options[:id].to_i) : klass.find(options[:id].to_i)
        DirectWriter.index obj
      end

      def unindex_task(options)
        klass = Kernel.const_get options[:class]
        obj   = klass.respond_to?(:get) ? klass.get(options[:id].to_i) : klass.find(options[:id].to_i)
        DirectWriter.unindex obj
      end

      def reindex_class_task(options)
        klass = Kernel.const_get options[:class]
        DirectWriter.reindex_class klass, :verbose => false
      end

    end
  end
end
# encoding: utf-8

module XapianDb
  module Adapters

    # Adapter for ActiveRecord. To use it, configure it like this:
    #   XapianDb::Config.setup do |config|
    #     config.adapter :active_record
    #   end
    # This adapter does the following:
    # - adds the instance method <code>xapian_id</code> to an indexed class
    # - adds the class method <code>rebuild_xapian_index</code> to an indexed class
    # - adds an after commit block to an indexed class to update the index
    # - adds an after destroy block to an indexed class to update the index
    # - adds the instance method <code>indexed_object</code> to the module that will be included
    #   in every found xapian document
    # @author Gernot Kogler

     class ActiveRecordAdapter < BaseAdapter

       class << self

         # Implement the class helper methods
         # @param [Class] klass The class to add the helper methods to
         def add_class_helper_methods_to(klass)

           # Add the helpers from the base class
           super klass

           klass.instance_eval do
             # define the method to retrieve a unique key
             define_method(:xapian_id) do
               "#{self.class}-#{self.id}"
             end

           end

           klass.class_eval do

             # add the after save logic
             after_commit do
               blueprint = XapianDb::DocumentBlueprint.blueprint_for klass
               if blueprint.should_index?(self)
                 XapianDb.index(self)
               else
                 XapianDb.unindex(self)
               end
             end

             # add the after destroy logic
             after_destroy do
               XapianDb.unindex(self)
             end

             # Add a method to reindex all models of this class
             define_singleton_method(:rebuild_xapian_index) do |options={}|
               options[:primary_key] = klass.primary_key
               XapianDb.reindex_class(klass, options)
             end
           end

         end

         # Implement the document helper methods on a module
         # @param [Module] a_module The module to add the helper methods to
         def add_doc_helper_methods_to(a_module)
           a_module.instance_eval do

             # Implement access to the model id
             define_method :id do
               return @id unless @d.nil?
               # retrieve the class and id from data
               klass_name, id = data.split("-")
               @id = id.to_i
             end

             # Implement access to the indexed object
             define_method :indexed_object do
               return @indexed_object unless @indexed_object.nil?
               # retrieve the class and id from data
               klass_name, id = data.split("-")
               klass = Kernel.const_get(klass_name)
               @indexed_object = klass.find(id.to_i)
             end

           end

         end

       end
     end
   end
 end

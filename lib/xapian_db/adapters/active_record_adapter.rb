# encoding: utf-8

# Adapter for ActiveRecord. To use it, simply set it as the
# default for any DocumentBlueprint or a specific DocumentBlueprint

module XapianDb
  module Adapters
     
     class ActiveRecordAdapter

       class << self
         
         # Implement the class helper methods
         def add_class_helper_methods_to(klass)

           klass.instance_eval do
             # define the method to retrieve a unique key
             define_method(:xapian_id) do
               "#{self.class}-#{self.id}"
             end
                          
           end
         
           klass.class_eval do
             
             # add the after save logic
             after_save do
               XapianDb::Config.writer.index(self)
             end
             
             # add the after destroy logic
             after_destroy do
               XapianDb::Config.writer.unindex(self)
             end

             # Add a method to reindex all models of this class
             define_singleton_method(:rebuild_xapian_index) do
               # db = XapianDb::Adapters::ActiveRecordAdapter.database
               # # First, delete all docs of this class
               # db.delete_docs_of_class(klass)
               # obj_count = klass.count
               # puts "Reindexing #{obj_count} objects..."
               # pbar = ProgressBar.new("Status", obj_count)
               # klass.all.each do |obj|
               #   doc = @@blueprint.indexer.build_document_for(obj)
               #   db.store_doc(doc)
               #   pbar.inc
               # end
               # db.commit
               XapianDb::Config.writer.reindex_class(klass)
             end
           end
         
         end
       
         # Implement the document helper methods
         def add_doc_helper_methods_to(a_module)
           a_module.instance_eval do
             # Implement access to the indexed object
             define_method :indexed_object do
               return @indexed_object unless @indexed_object.nil? 
               # retrieve the object id from data
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

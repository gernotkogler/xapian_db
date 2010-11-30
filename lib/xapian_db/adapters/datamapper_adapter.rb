# encoding: utf-8

# Adapter for datamapper. To use it, simply set it as the
# default for any DocumentBlueprint or a specific DocumentBlueprint

module XapianDb
  module Adapters
     
     class DatamapperAdapter

       class << self
         
         attr_accessor :database
         
         # Implement the helper methods
         def add_helper_methods_to(klass)

           raise "Database not set for DatamapperAdapter" unless @database
           
           klass.instance_eval do
             # define the method to retrieve a unique key
             define_method(:xapian_id) do
               "#{self.class}-#{self.id}"
             end
           end
         
           klass.class_eval do
             
             @@blueprint = XapianDb::DocumentBlueprint.blueprint_for(klass)
             
             # add the after save logic
             after :save do
               doc = @@blueprint.indexer.build_document_for(self)
               XapianDb::Adapters::DatamapperAdapter.database.store_doc(doc)
             end

             # add the after destroy logic
             after :destroy do
               XapianDb::Adapters::DatamapperAdapter.database.delete_doc_with_unique_term("#{self.class}-#{self.id}")
             end

           end
         
         end
       
       end
       
     end
     
   end
 end

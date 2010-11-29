# encoding: utf-8

# Adapter for datamapper. To use it, simply set it as the
# default for any DocumentBlueprint or a specific DocumentBlueprint

module XapianDb
  module Adapters
     
     class DatamapperAdapter

       # Implement the helper methods
       def self.add_helper_methods_to(klass)
         klass.instance_eval do
           define_method(:xapian_id) do
             "#{self.class}-#{self.id}"
           end
         end
         # TODO: Add after save and after delete hooks
       end
       
     end
     
   end
 end

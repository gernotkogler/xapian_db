module XapianDb
  module Adapters
     
     class DatamapperAdapter
       def self.add_helper_methods_to(klass)

         klass.instance_eval do
           define_method(:xapian_id) do
             "#{self.class}-#{self.id}"
           end
         end

       end
     end
     
   end
 end

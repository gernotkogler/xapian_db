# encoding: utf-8

# The generic adapter is a universal adapater that can be used for any
# ruby class. To use the generic adapter (which is the default),
# configure the expression that generates a unique key from your objects 
# using the method 'unique_key'.
module XapianDb
  module Adapters
     
    class GenericAdapter

      class << self
        
        # Define the unique key expression
        def unique_key(&block)
          @unique_key_block = block
        end
        
        # Implement the class helper methods
        def add_class_helper_methods_to(klass)
          raise "Unique key is not configured for generic adapter!" if @unique_key_block.nil?
          expression = @unique_key_block
          klass.instance_eval do
            define_method(:xapian_id) do
              instance_eval &expression
            end
          end
        end
        
        # Implement the document helper methods
        def add_doc_helper_methods_to(obj)
          # We have none so far
        end
        
      end

    end
     
  end
   
end
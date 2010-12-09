# encoding: utf-8

module XapianDb
  module Adapters

    # The generic adapter is a universal adapater that can be used for any
    # ruby class. To use the generic adapter (which is the default),
    # configure the expression that generates a unique key from your objects
    # using the method 'unique_key'.
    # This adapter does the following:
    # - adds the instance method <code>xapian_id</code> to an indexed class
    # @author Gernot Kogler
    class GenericAdapter

      class << self

        # Define the unique key expression
        # @example Use the same unique expression like the active record adapter (assuming your objects have an id)
        #   XapianDb::Adapters::GenericAdapter.unique_key do
        #     "#{self.class}-#{self.id}"
        #   end
        def unique_key(&block)
          @unique_key_block = block
        end

        # Implement the class helper methods
        # @param [Class] klass The class to add the helper methods to
        def add_class_helper_methods_to(klass)
          raise "Unique key is not configured for generic adapter!" if @unique_key_block.nil?
          expression = @unique_key_block
          klass.instance_eval do
            define_method(:xapian_id) do
              instance_eval &expression
            end
          end
        end

        # Implement the document helper methods on a module. So far there are none
        # @param [Module] a_module The module to add the helper methods to
        def add_doc_helper_methods_to(obj)
          # We have none so far
        end

      end

    end

  end

end
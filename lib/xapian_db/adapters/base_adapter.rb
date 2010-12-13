# encoding: utf-8

module XapianDb
  module Adapters

    # base class for orm adapters.
    # This adapter does the following:
    # - adds the class method <code>search(expression)</code> to an indexed class
    # @author Gernot Kogler

     class BaseAdapter

       class << self

         # Implement the class helper methods
         # @param [Class] klass The class to add the helper methods to
         def add_class_helper_methods_to(klass)

           klass.class_eval do

             # Add a method to search models of this class
             define_singleton_method(:search) do |expression|
               XapianDb.database.search "indexed_class:#{klass.name.downcase} and (#{expression})"
             end

           end
         end
       end
     end
   end
 end

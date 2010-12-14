# encoding: utf-8

module XapianDb
  module Adapters

    # base class for all adapters.
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
               class_scope = "indexed_class:#{klass.name.downcase}"
               result = XapianDb.database.search "#{class_scope} and (#{expression})"

               # Remove the class scope from the spelling suggestion (if any)
               unless result.spelling_suggestion.empty?
                 scope_length = "#{class_scope} and (".size
                 result.spelling_suggestion = result.spelling_suggestion.slice scope_length..-2
               end
               result
             end

           end
         end
       end
     end
   end
 end

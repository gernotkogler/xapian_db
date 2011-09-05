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
             # Options:
             # - :order          (Array<Symbol>) Accepts an array of attribute names for sorting
             # - :sort_decending (Boolean)       Allows to reverse the sorting
             define_singleton_method(:search) do |expression, options={}|

               # return an empty search if no search expression is given
               return XapianDb.database.search(nil) if expression.nil? || expression.strip.empty?

               options = {:sort_decending => false}.merge options
               class_scope = "indexed_class:#{klass.name.downcase}"

               order = options.delete :order
               if order
                 attr_names             = [order].flatten
                 blueprint              = XapianDb::DocumentBlueprint.blueprint_for klass
                 options[:sort_indices] = attr_names.map {|attr_name| XapianDb::DocumentBlueprint.value_number_for(attr_name) }
               end
               result = XapianDb.database.search "#{class_scope} and (#{expression})", options

               # Remove the class scope from the spelling suggestion (if any)
               if result.spelling_suggestion
                 scope_length = "#{class_scope} and (".size
                 result.spelling_suggestion = result.spelling_suggestion.slice scope_length..-2
               end
               result
             end

             define_singleton_method(:find_similar_to) do |reference|
              return XapianDb.database.find_similar_to reference, :class => klass
             end

             # Add a method to search atribute facets of this class
             define_singleton_method(:facets) do |attribute, expression|
               class_scope  = "indexed_class:#{klass.name.downcase}"
               XapianDb.database.facets attribute, "#{class_scope} and (#{expression})"
             end

           end
         end
       end
     end
   end
 end

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

               if options[:order]
                 attr_names             = [options[:order]].flatten
                 blueprint              = XapianDb::DocumentBlueprint.blueprint_for klass
                 sort_indices           = attr_names.map {|attr_name| blueprint.value_index_for(attr_name)}
                 options[:sort_indices] = attr_names.map {|attr_name| blueprint.value_index_for(attr_name)}
               end
               result = XapianDb.database.search "#{class_scope} and (#{expression})", options

               # Remove the class scope from the spelling suggestion (if any)
               unless result.spelling_suggestion.empty?
                 scope_length = "#{class_scope} and (".size
                 result.spelling_suggestion = result.spelling_suggestion.slice scope_length..-2
               end
               result
             end

             # Add a method to search atribute facets of this class
             define_singleton_method(:facets) do |attr_name, expression|

               # return an empty hash if no search expression is given
               return {} if expression.nil? || expression.strip.empty?

               class_scope = "indexed_class:#{klass.name.downcase}"
               blueprint   = XapianDb::DocumentBlueprint.blueprint_for klass
               value_index = blueprint.value_index_for attr_name.to_sym

               query_parser        = QueryParser.new(XapianDb.database)
               query                = query_parser.parse("#{class_scope} and (#{expression})")
               enquiry              = Xapian::Enquire.new(XapianDb.database.reader)
               enquiry.query        = query
               enquiry.collapse_key = value_index
               facets = {}
               enquiry.mset(0, XapianDb.database.size).matches.each do |match|
                 facet_value = YAML::load match.document.values[value_index].value
                 # We must add 1 to the collapse_count since collapse_count means
                 # "how many other matches are there?"
                 facets[facet_value] = match.collapse_count + 1
               end
               facets

             end

           end
         end
       end
     end
   end
 end

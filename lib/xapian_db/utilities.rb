# encoding: utf-8

# Collection of utility methods
# @author Gernot Kogler
module XapianDb
  module Utilities

    # Convert a string to camel case
    # @param [String] The string to camelize
    # @return [String] The camelized string
    def camelize(string)
      string.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
    end

    # Taken from Rails
    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end

  end
end
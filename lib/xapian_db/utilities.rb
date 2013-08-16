# encoding: utf-8

# Collection of utility methods
# @author Gernot Kogler
module XapianDb
  module Utilities

    extend self

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

      names.inject(Object) do |constant, name|
        if constant == Object
          constant.const_get(name)
        else
          candidate = constant.const_get(name)
          next candidate if constant.const_defined?(name, false)
          next candidate unless Object.const_defined?(name)

          # Go down the ancestors to check it it's owned
          # directly before we reach Object or the end of ancestors.
          constant = constant.ancestors.inject do |const, ancestor|
            break const    if ancestor == Object
            break ancestor if ancestor.const_defined?(name, false)
            const
          end

          # owner is in Object, so raise
          constant.const_get(name, false)
        end
      end
    end

    # Taken from Rails
    def assert_valid_keys(hash, *valid_keys)
      unknown_keys = hash.keys - [valid_keys].flatten
      raise(ArgumentError, "Unsupported option(s) detected: #{unknown_keys.join(", ")}") unless unknown_keys.empty?
    end

  end
end

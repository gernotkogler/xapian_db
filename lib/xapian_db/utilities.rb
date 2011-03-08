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

  end
end
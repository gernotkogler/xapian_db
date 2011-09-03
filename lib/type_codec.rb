# encoding: utf-8

# This class is responsible for encoding and decoding values depending on their
# type

require "bigdecimal"

module XapianDb

  class TypeCodec

    extend XapianDb::Utilities

    # Get the codec for a type
    # @param [Symbol] type a supported type as a string or symbol.
    #   The following types are supported:
    #     - :date
    # @return [DateCodec]
    def self.codec_for(type)
      begin
        constantize "XapianDb::TypeCodec::#{camelize("#{type}_codec")}"
      rescue NameError
        raise ArgumentError.new "no codec defined for type #{type}"
      end
    end

    class GenericCodec

      # Encode an object to to its yaml representation
      # @param [Object] object an object to encode
      # @return [String] the yaml string
      def self.encode(object)
        begin
          object.to_yaml
        rescue NoMethodError
          raise ArgumentError.new "#{object} does not support yaml serialization"
        end
      end

      # Decode an object from a yaml string
      # @param [String] yaml_string a yaml string representing the object
      # @return [Object] the parsed object
      def self.decode(yaml_string)
        begin
          YAML::load yaml_string
        rescue ArgumentError
          raise ArgumentError.new "'#{yaml_string}' cannot be loaded by YAML"
        end
      end
    end

    class DateCodec

      # Encode a date to a string in the format 'yyyymmdd'
      # @param [Date] date a date object to encode
      # @return [String] the encoded date
      def self.encode(date)
        begin
          date.strftime "%Y%m%d"
        rescue NoMethodError
          raise ArgumentError.new "#{date} was expected to be a date"
        end
      end

      # Decode a string to a date
      # @param [String] date_as_string a string representing a date
      # @return [Date] the parsed date
      def self.decode(date_as_string)
        begin
          Date.parse date_as_string
        rescue ArgumentError
          raise ArgumentError.new "'#{date_as_string}' cannot be converted to a date"
        end
      end
    end

  end
end

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

      # Encode an object to its yaml representation
      # @param [Object] object an object to encode
      # @return [String] the yaml string
      def self.encode(object)
        begin
          if object.respond_to?(:attributes)
            object.attributes.to_yaml
          else
            object.to_yaml
          end
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
        rescue TypeError
          raise ArgumentError.new "'#{yaml_string}' cannot be loaded by YAML"
        end
      end
    end

    class StringCodec

      # Encode an object to a string
      # @param [Object] object an object to encode
      # @return [String] the string
      def self.encode(object)
        object.to_s
      end

      # Decode a string
      # @param [String] string a string
      # @return [String] the string
      def self.decode(string)
        string
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

    class NumberCodec

      # Encode a number to a sortable string
      # @param [Integer, BigDecimal, Float] number a number object to encode
      # @return [String] the encoded number
      def self.encode(number)
        begin
          Xapian::sortable_serialise number
        rescue TypeError
          raise ArgumentError.new "#{number} was expected to be a number"
        end
      end

      # Decode a string to a BigDecimal
      # @param [String] number_as_string a string representing a number
      # @return [BigDecimal] the decoded number
      def self.decode(encoded_number)
        begin
          BigDecimal.new(Xapian::sortable_unserialise(encoded_number).to_s)
        rescue TypeError
          raise ArgumentError.new "#{encoded_number} cannot be unserialized"
        end
      end
    end

  end
end

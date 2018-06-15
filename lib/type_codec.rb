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

    class JsonCodec

      # Encode an object to its json representation
      # @param [Object] object an object to encode
      # @return [String] the json string
      def self.encode(object)
        return nil if object.nil?
        begin
          object.to_json
        rescue NoMethodError
          raise ArgumentError.new "#{object} does not support json serialization"
        end
      end

      # Decode an object from a json string
      # @param [String] json_string a json string representing the object
      # @return [Hash] a ruby hash
      def self.decode(json_string)
        return nil if json_string.nil? || json_string == ""
        begin
          JSON.parse json_string
        rescue TypeError
          raise ArgumentError.new "'#{json_string}' cannot be parsed"
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
        string.force_encoding("UTF-8")
      end
    end

    class BooleanCodec

      # Encode a boolean value to a string
      # @param [Object] value a value to encode
      # @return [String] the string
      def self.encode(value)
        value.to_s
      end

      # Decode a string representing a boolean
      # @param [String] string a string
      # @return [Boolean] the boolean value
      def self.decode(string)
        string == "true"
      end
    end

    class DateCodec

      # Encode a date to a string in the format 'yyyymmdd'
      # @param [Date] date a date object to encode
      # @return [String] the encoded date
      def self.encode(date)
        return nil if date.nil?
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
        return nil if date_as_string.nil? || date_as_string.strip == ""
        begin
          Date.parse date_as_string
        rescue ArgumentError
          raise ArgumentError.new "'#{date_as_string}' cannot be converted to a date"
        end
      end
    end

    class DateTimeCodec

      # Encode a datetime to a string in the format 'yyyymmdd h:m:s+l'
      # @param [DateTime] datetime a datetime object to encode
      # @return [String] the encoded datetime
      def self.encode(datetime)
        return nil unless datetime
        begin
          datetime.strftime "%Y%m%d %H:%M:%S+%L"
        rescue NoMethodError
          raise ArgumentError.new "#{datetime} was expected to be a datetime"
        end
      end

      # Decode a string to a datetime
      # @param [String] datetime_as_string a string representing a datetime
      # @return [DateTime] the parsed datetime
      def self.decode(datetime_as_string)
        return nil if datetime_as_string.nil? || datetime_as_string.strip == ""
        begin
          DateTime.parse datetime_as_string
        rescue ArgumentError
          raise ArgumentError.new "'#{datetime_as_string}' cannot be converted to a datetime"
        end
      end
    end

    class NumberCodec

      # Encode a number to a sortable string
      # @param [Integer, BigDecimal, Bignum, Float] number a number object to encode
      # @return [String] the encoded number
      def self.encode(number)
        case number.class.name
          when "Fixnum", "Float", "Bignum", "Integer"
            Xapian::sortable_serialise number
          when "BigDecimal"
            Xapian::sortable_serialise number.to_f
          else
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

    class IntegerCodec

      # Encode an integer to a sortable string
      # @param [Integer] integer an integer to encode
      # @return [String] the encoded integer
      def self.encode(number)
        return nil if number.nil?
        case number.class.name
          when "Fixnum", "Integer"
            Xapian::sortable_serialise number
          else
            raise ArgumentError.new "#{number} was expected to be an integer"
        end
      end

      # Decode a string to an integer
      # @param [String] integer_as_string a string representing an integer
      # @return [Integer] the decoded integer
      def self.decode(encoded_integer)
        begin
          return nil if encoded_integer.nil? || encoded_integer.to_s.strip == ""
          Xapian::sortable_unserialise(encoded_integer).to_i
        rescue TypeError
          raise ArgumentError.new "#{encoded_integer} cannot be unserialized"
        end
      end
    end

  end
end

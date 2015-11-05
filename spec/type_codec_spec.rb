# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe XapianDb::TypeCodec do

  describe ".codec_for(:type)" do

    it "returns a codec for the given type" do
      expect(described_class.codec_for(:string)).to eq(XapianDb::TypeCodec::StringCodec)
      expect(described_class.codec_for(:date)).to eq(XapianDb::TypeCodec::DateCodec)
      expect(described_class.codec_for(:date_time)).to eq(XapianDb::TypeCodec::DateTimeCodec)
      expect(described_class.codec_for(:number)).to eq(XapianDb::TypeCodec::NumberCodec)
    end

    it "raises an argument error if the type is unknown" do
      expect { described_class.codec_for(:unsupported) }.to raise_error ArgumentError
    end

  end
end

describe XapianDb::TypeCodec::JsonCodec do

  describe "encode(object)" do

    it "encodes an object to its json representation" do
      hash = { x: "y" }
      expect(described_class.encode(hash)).to eq(hash.to_json)
    end

    it "raises an ArgumentError if the object does not respond to to_json" do
      object = Object.new
      allow(object).to receive(:to_json).and_raise NoMethodError
      expect { described_class.encode(object) }.to raise_error ArgumentError
    end

    it "returns nil if the object is nil" do
      expect(described_class.encode(nil)).to be_nil
    end

  end

  describe "decode(json_string)" do

    it "decodes a json string representing the object to the object" do
      json_string = { x: "y" }.to_json
      expect(described_class.decode(json_string)).to eq(JSON.parse(json_string))
    end

    it "decodes nil to nil" do
      expect(described_class.decode(nil)).to be_nil
    end

    it "decodes an empty string to nil" do
      expect(described_class.decode("")).to be_nil
    end

    it "raises an ArgumentError if the given argument cannot pe parsed by JSON" do
      argument = 1
      expect { described_class.decode(argument) }.to raise_error ArgumentError
    end

  end
end

describe XapianDb::TypeCodec::StringCodec do

  describe "encode(object)" do

    it "encodes an object to a string" do
      expect(described_class.encode("string")).to eq("string")
    end
  end

  describe "decode(string)" do

    it "returns the string given as an argument" do
      expect(described_class.decode("string")).to eq("string")
    end
  end
end

describe XapianDb::TypeCodec::BooleanCodec do

  describe "encode(value)" do

    it "encodes a booelan to a string" do
      expect(described_class.encode(true)).to eq("true")
      expect(described_class.encode(false)).to eq("false")
    end
  end

  describe "decode(value)" do

    it "returns the boolean value" do
      expect(described_class.decode("true")).to be_truthy
      expect(described_class.decode("false")).to be_falsey
    end
  end
end

describe XapianDb::TypeCodec::DateCodec do

  describe "encode(date)" do

    it "encodes a date to a string with format yyyymmdd" do
      expect(described_class.encode(Date.new(2011, 1, 1))).to eq("20110101")
    end

    it "raises an argument error if the given object is not a date" do
      expect { described_class.encode("20110101") }.to raise_error "20110101 was expected to be a date"
    end

    it "should return nil when a nil value is supplied" do
      expect(described_class.encode(nil)).not_to be
    end
  end

  describe "decode(string)" do

    it "returns nil if nil is passed in" do
      expect(described_class.decode(nil)).not_to be
    end

    it "returns nil if an empty string is passed in" do
      expect(described_class.decode(" ")).not_to be
    end

    it "decodes a string representing a date to a date" do
      expect(described_class.decode("20110101")).to eq(Date.new(2011, 1, 1))
    end

    it "raises an argument error if the given string cannot be parsed by the date class" do
      expect { described_class.decode("not a date") }.to raise_error "'not a date' cannot be converted to a date"
    end
  end

end

describe XapianDb::TypeCodec::DateTimeCodec do

  describe "encode(datetime)" do

    it "encodes a datetime to a string with format yyyymmdd h:m:s+l" do
      expect(described_class.encode(DateTime.new(2011, 1, 1, 11, 30, 15))).to eq("20110101 11:30:15+000")
    end

    it "raises an argument error if the given object is not a datetime" do
      expect { described_class.encode("20110101") }.to raise_error "20110101 was expected to be a datetime"
    end

    it "should return nil when a nil value is supplied" do
      expect(described_class.encode(nil)).not_to be
    end
  end

  describe "decode(string)" do

    it "returns nil if nil is passed in" do
      expect(described_class.decode(nil)).not_to be
    end

    it "returns nil if an empty string is passed in" do
      expect(described_class.decode(" ")).not_to be
    end

    it "decodes a string representing a date to a date" do
      expect(described_class.decode("20110101 11:30:15+000")).to eq(DateTime.new(2011, 1, 1, 11, 30, 15))
    end

    it "raises an argument error if the given string cannot be parsed by the date class" do
      expect { described_class.decode("not a datetime") }.to raise_error "'not a datetime' cannot be converted to a datetime"
    end
  end

end

describe XapianDb::TypeCodec::NumberCodec do

  describe "encode(number)" do

    it "encodes a number using the xapian sortable_serialise method" do
      expect(described_class.encode(1)).to eq(Xapian::sortable_serialise(1))
    end

    it "can handle big decimals" do
      expect(described_class.encode(BigDecimal("1"))).to eq(Xapian::sortable_serialise(1))
    end

    it "can handle big numbers" do
      first_bignum = 2**(0.size * 8 - 2)
      expect(described_class.encode(first_bignum)).to eq(Xapian::sortable_serialise(first_bignum))
    end

    it "raises an argument error if the given object is not a number" do
      expect { described_class.encode("X") }.to raise_error "X was expected to be a number"
    end
  end

  describe "decode(number_as_string)" do

    it "decodes a string representing a number to a BigDecimal" do
      encoded_number = Xapian::sortable_serialise(1.5)
      expect(described_class.decode(encoded_number)).to eq(BigDecimal.new("1.5"))
    end

    it "raises an argument error if the argument ist not a string" do
      expect { described_class.decode(1) }.to raise_error "1 cannot be unserialized"
    end
  end

end

describe XapianDb::TypeCodec::IntegerCodec do

  describe "encode(integer)" do

    it "encodes an integer using the xapian sortable_serialise method" do
      expect(described_class.encode(1)).to eq(Xapian::sortable_serialise(1))
    end

    it "raises an argument error if the given object is not an integer" do
      expect { described_class.encode("X") }.to raise_error "X was expected to be an integer"
    end

    it "should return nil when a nil value is supplied" do
      expect(described_class.encode(nil)).not_to be
    end
  end

  describe "decode(integer_as_string)" do

    it "decodes a string representing a number to a BigDecimal" do
      encoded_number = Xapian::sortable_serialise(1)
      expect(described_class.decode(encoded_number)).to eq(1)
    end

    it "returns nil if an empty string is passed in" do
      expect(described_class.decode(" ")).not_to be
    end

    it "raises an argument error if the argument ist not a string" do
      expect { described_class.decode(1) }.to raise_error "1 cannot be unserialized"
    end
  end

end

# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe XapianDb::TypeCodec do

  describe ".codec_for(:type)" do

    it "returns a codec for the given type" do
      described_class.codec_for(:string).should == XapianDb::TypeCodec::StringCodec
      described_class.codec_for(:date).should == XapianDb::TypeCodec::DateCodec
      described_class.codec_for(:date_time).should == XapianDb::TypeCodec::DateTimeCodec
      described_class.codec_for(:number).should == XapianDb::TypeCodec::NumberCodec
    end

    it "raises an argument error if the type is unknown" do
      lambda { described_class.codec_for(:unsupported) }.should raise_error ArgumentError
    end

  end
end

describe XapianDb::TypeCodec::GenericCodec do

  describe "encode(object)" do

    it "encodes an object to its yaml representation" do
      object = "some text"
      described_class.encode(object).should == object.to_yaml
    end

    it "encodes an objects attributes hash if it has one" do
      hash = { :id => 1, :name => "Kogler" }
      object = Object.new
      object.stub!(:attributes).and_return hash
      described_class.encode(object).should == hash.to_yaml
    end

    it "raises an ArgumentError if the object does not respond to to_yaml" do
      object = Object.new
      object.stub!(:to_yaml).and_raise NoMethodError
      lambda { described_class.encode(object) }.should raise_error ArgumentError
    end

  end

  describe "decode(yaml_string)" do

    it "decodes a yaml string representing the object to the object" do
      yaml_string = "some text".to_yaml
      described_class.decode(yaml_string).should == YAML::load(yaml_string)
    end

    it "raises an ArgumentError if the given argument cannot pe parsed by YAML" do
      argument = 1
      lambda { described_class.decode(argument) }.should raise_error ArgumentError
    end

  end
end

describe XapianDb::TypeCodec::StringCodec do

  describe "encode(object)" do

    it "encodes an object to a string" do
      described_class.encode("string").should == "string"
    end
  end

  describe "decode(string)" do

    it "returns the string given as an argument" do
      described_class.decode("string").should == "string"
    end
  end
end

describe XapianDb::TypeCodec::DateCodec do

  describe "encode(date)" do

    it "encodes a date to a string with format yyyymmdd" do
      described_class.encode(Date.new(2011, 1, 1)).should == "20110101"
    end

    it "raises an argument error if the given object is not a date" do
      lambda { described_class.encode("20110101") }.should raise_error "20110101 was expected to be a date"
    end

    it "should return nil when a nil value is supplied" do
      described_class.encode(nil).should_not be
    end
  end

  describe "decode(string)" do

    it "returns nil if nil is passed in" do
      described_class.decode(nil).should_not be
    end

    it "returns nil if an empty string is passed in" do
      described_class.decode(" ").should_not be
    end

    it "decodes a string representing a date to a date" do
      described_class.decode("20110101").should == Date.new(2011, 1, 1)
    end

    it "raises an argument error if the given string cannot be parsed by the date class" do
      lambda { described_class.decode("not a date") }.should raise_error "'not a date' cannot be converted to a date"
    end
  end

end

describe XapianDb::TypeCodec::DateTimeCodec do

  describe "encode(datetime)" do

    it "encodes a datetime to a string with format yyyymmdd h:m:s+l" do
      described_class.encode(DateTime.new(2011, 1, 1, 11, 30, 15)).should == "20110101 11:30:15+000"
    end

    it "raises an argument error if the given object is not a datetime" do
      lambda { described_class.encode("20110101") }.should raise_error "20110101 was expected to be a datetime"
    end

    it "should return nil when a nil value is supplied" do
      described_class.encode(nil).should_not be
    end
  end

  describe "decode(string)" do

    it "returns nil if nil is passed in" do
      described_class.decode(nil).should_not be
    end

    it "returns nil if an empty string is passed in" do
      described_class.decode(" ").should_not be
    end

    it "decodes a string representing a date to a date" do
      described_class.decode("20110101 11:30:15+000").should == DateTime.new(2011, 1, 1, 11, 30, 15)
    end

    it "raises an argument error if the given string cannot be parsed by the date class" do
      lambda { described_class.decode("not a datetime") }.should raise_error "'not a datetime' cannot be converted to a datetime"
    end
  end

end

describe XapianDb::TypeCodec::NumberCodec do

  describe "encode(number)" do

    it "encodes a number using the xapian sortable_serialise method" do
      described_class.encode(1).should == Xapian::sortable_serialise(1)
    end

    it "can handle big decimals" do
      described_class.encode(BigDecimal("1")).should == Xapian::sortable_serialise(1)
    end

    it "can handle big numbers" do
      first_bignum = 2**(0.size * 8 - 2)
      described_class.encode(first_bignum).should == Xapian::sortable_serialise(first_bignum)
    end

    it "raises an argument error if the given object is not a number" do
      lambda { described_class.encode("X") }.should raise_error "X was expected to be a number"
    end
  end

  describe "decode(number_as_string)" do

    it "decodes a string representing a number to a BigDecimal" do
      encoded_number = Xapian::sortable_serialise(1.5)
      described_class.decode(encoded_number).should == BigDecimal.new("1.5")
    end

    it "raises an argument error if the argument ist not a string" do
      lambda { described_class.decode(1) }.should raise_error "1 cannot be unserialized"
    end
  end

end

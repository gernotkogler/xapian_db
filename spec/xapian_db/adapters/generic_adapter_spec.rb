# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/xapian_db/adapters/generic_adapter.rb')

describe XapianDb::Adapters::GenericAdapter do

  class MyClass
    attr_accessor :my_unique_key

    def initialize(key)
      @my_unique_key = key
    end
  end

  before :each do
    XapianDb.setup do |config|
      config.adapter :generic
    end
  end

  describe ".unique_key do" do
    it "stores a block that generates a unique key" do
      XapianDb::Adapters::GenericAdapter.unique_key do
        "#{my_unique_key}"
      end
    end
  end

  describe ".add_helper_methods_to(klass)" do

    it "should raise an exception if the unique key is not configured" do
      XapianDb::Adapters::GenericAdapter.unique_key # undef the unique key
      expect{XapianDb::Adapters::GenericAdapter.add_class_helper_methods_to(MyClass)}.to raise_error
    end

    it "should add the method 'xapian_id' to the configured class" do
      XapianDb::Adapters::GenericAdapter.unique_key do
        "#{my_unique_key}"
      end
      XapianDb::DocumentBlueprint.setup(:MyClass)
      obj = MyClass.new(1)
      expect(obj.xapian_id).to eq(obj.my_unique_key.to_s)
    end

    it "adds the helper methods from the base class" do
      XapianDb::Adapters::GenericAdapter.add_class_helper_methods_to MyClass
      expect(MyClass).to respond_to(:search)
    end

  end

end

# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Adapters::GenericAdapter do

  class MyClass    
    attr_accessor :my_unique_key
    
    def initialize(key)
      @my_unique_key = key
    end
  end
  
  before :each do
    XapianDb::DocumentBlueprint.default_adapter = XapianDb::Adapters::GenericAdapter
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
      lambda{XapianDb::Adapters::GenericAdapter.add_helper_methods_to(MyClass)}.should raise_error
    end

    it "should add the method 'xapian_id' to the configured class" do
      XapianDb::Adapters::GenericAdapter.unique_key do
        "#{my_unique_key}"
      end
      XapianDb::DocumentBlueprint.setup(MyClass)
      obj = MyClass.new(1)
      obj.xapian_id.should == obj.my_unique_key.to_s
    end
    
  end
  
end
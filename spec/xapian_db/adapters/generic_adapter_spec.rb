# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Adapters::GenericAdapter do

  before :each do
    XapianDb::DocumentBlueprint.default_adapter = XapianDb::Adapters::GenericAdapter
  end
  
  describe ".unique_key do" do
    it "stores a block that generates a unique key" do
      XapianDb::Adapters::GenericAdapter.unique_key do
        "#{object_id}"
      end
    end
  end
  
  describe ".add_helper_methods_to(klass)" do
    it "adds the method 'xapian_id' to the configured class" do
      XapianDb::Adapters::GenericAdapter.unique_key do
        "#{object_id}"
      end
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      obj = IndexedObject.new(1)
      obj.xapian_id.should == obj.object_id.to_s
    end
  end
  
end
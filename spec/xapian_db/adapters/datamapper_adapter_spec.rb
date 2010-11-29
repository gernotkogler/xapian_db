# encoding: utf-8

# Theses specs describe and test the helper methods that are added to indexed classes
# by the datamapper adapter
# @author Gernot Kogler

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Adapters::DatamapperAdapter do

  before :each do
    XapianDb::DocumentBlueprint.default_adapter = XapianDb::Adapters::DatamapperAdapter
    XapianDb::DocumentBlueprint.setup(IndexedObject)
  end
  
  describe ".add_helper_methods_to(klass)" do
    it "adds the method 'xapian_id' to the configured class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      IndexedObject.new(1).respond_to?(:xapian_id).should be_true
    end
  end
  
  describe ".xapian_id" do
    it "returns a unique id composed of the class name and the id" do
      obj = IndexedObject.new(1)
      obj.xapian_id.should == "#{obj.class}-#{obj.id}"
    end
  end
  
end
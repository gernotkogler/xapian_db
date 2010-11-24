# encoding: utf-8

# Theses specs describe and test the helper methods that are added to indexed classes
# by the datamapper adapter
# @author Gernot Kogler

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Adapters::DatamapperAdapter do

  before :each do
    XapianDb::DocumentBlueprint.default_adapter = XapianDb::Adapters::DatamapperAdapter
    XapianDb::DocumentBlueprint.setup(IndexedObject)
  end
  
  describe ".xapian_id" do

    it "returns a unique id composed of the class name and the id" do
      obj = IndexedObject.new(1)
      obj.xapian_id.should == "#{obj.class}-#{obj.id}"
    end
    
  end
  
end
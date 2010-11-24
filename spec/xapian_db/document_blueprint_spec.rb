# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::DocumentBlueprint do

  describe ".default_adapter= (singleton)" do

    it "sets the default adapter for all indexed classes" do
      XapianDb::DocumentBlueprint.default_adapter = DemoAdapter
    end
    
  end

  describe ".setup (singleton)" do
    
    it "stores a blueprint for a given class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).should be_a_kind_of(XapianDb::DocumentBlueprint)
    end

    it "adds the method 'xapian_id' to the configured class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      IndexedObject.new(1).respond_to?(:xapian_id).should be_true
    end
    
  end
  
  describe ".adapter=" do
    
    it "sets the adpater for the configured class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.adapter = DemoAdapter
      end
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).adapter.should == DemoAdapter
    end
    
  end
  
end
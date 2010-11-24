# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::DocumentBlueprint do

  describe ".define_unique_key_pattern" do

    it "stores the pattern to retrieve a unique key for an object" do
      XapianDb::DocumentBlueprint.define_unique_key_pattern {"#{self.class}-#{self.id}"}
    end
    
  end

  describe ".setup" do
    
    it "stores a blueprint for a given class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      XapianDb::DocumentBlueprint.blueprint_for(IndexedObject).should be_a_kind_of(XapianDb::DocumentBlueprint)
    end

    it "adds the method 'xapian_id' to the configured class" do
      XapianDb::DocumentBlueprint.setup(IndexedObject)
      IndexedObject.new(1).respond_to?(:xapian_id).should be_true
    end
    
  end
  
end
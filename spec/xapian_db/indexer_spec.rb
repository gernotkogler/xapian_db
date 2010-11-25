# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Indexer do

  describe ".xapian_document" do
  
    it "creates a Xapian::Document from an configured object" do
      blueprint = XapianDb::DocumentBlueprint.new
      obj       = IndexedObject.new(1)
      XapianDb::Indexer.new(blueprint).build_document_for(obj).should be_a_kind_of(Xapian::Document)
    end

    it "inserts the xapian_id into the data property of the Xapian::Document" do
      blueprint = XapianDb::DocumentBlueprint.new
      obj       = IndexedObject.new(1)
      doc = XapianDb::Indexer.new(blueprint).build_document_for(obj)
      doc.data.should == obj.xapian_id
    end

    it "adds values for the configured methods" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.field :id
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      obj       = IndexedObject.new(1)
      doc       = blueprint.indexer.build_document_for(obj)
      doc.values[0].value.should == obj.id.to_s
    end
    
  end
    
end
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Indexer do

  describe ".xapian_document" do
  
    it "creates a Xapian::Document from a XapianDb::Document" do
      blueprint = XapianDb::DocumentBlueprint.new
      obj       = IndexedObject.new(1)
      XapianDb::Indexer.new(blueprint).build_document_for(obj).should be_a_kind_of(Xapian::Document)
    end
    
  end
    
end
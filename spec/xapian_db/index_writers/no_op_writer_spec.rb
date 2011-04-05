# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::NoOpWriter do

  before :each do
    XapianDb.setup do |config|
      config.adapter  :generic
      config.database :memory
      config.writer   :direct
    end
    XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
      blueprint.attribute :id
      blueprint.attribute :text
    end
  end

  let(:object) {
    obj = IndexedObject.new(1)
    obj.stub!(:text).and_return("Some text")
    obj
  }
  let(:writer) { XapianDb::IndexWriters::NoOpWriter.new }

  describe "#index(obj)" do
    it "does nothing" do
      writer.index object
      XapianDb.database.size.should == 0
    end
  end

  describe "#unindex(obj)" do

    before :each do
      XapianDb::IndexWriters::DirectWriter.index object
    end

    it "does nothing" do
      writer.unindex object
      XapianDb.database.size.should == 1 # the object indexed in the before block
    end
  end

  describe "#reindex(klass)" do

    it "should raise a 'not supported' exception" do
      lambda { writer.reindex_class IndexedObject }.should raise_error "rebuild_xapian_index is not supported inside a block with auto indexing disabled"
    end

  end
end
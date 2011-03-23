# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::TransactionalWriter do

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
  let(:writer) { XapianDb::IndexWriters::TransactionalWriter.new }

  describe "#index(obj)" do
    it "registers an index request for an object" do
      writer.index object
      writer.index_requests.size.should == 1
    end
  end

  describe "#unindex(obj)" do

    it "registers an index request for an object" do
      writer.unindex object
      writer.unindex_requests.size.should == 1
    end
  end

  describe "#reindex(klass)" do

    it "should raise a 'not supported' exception" do
      lambda { writer.reindex_class IndexedObject }.should raise_error "rebuild_xapian_index is not supported in transactions"
    end

  end

  describe "#commit_using(writer)" do

    it "commits the index requests to the database", :working => true do
      writer.index object
      XapianDb.database.size.should == 0 # not commited yet
      writer.commit_using XapianDb::IndexWriters::DirectWriter
      XapianDb.database.size.should == 1
    end

    it "commits the unindex requests to the database" do
      XapianDb::IndexWriters::DirectWriter.index object
      XapianDb.database.size.should == 1
      writer.unindex object
      XapianDb.database.size.should == 1 # not commited yet
      writer.commit_using XapianDb::IndexWriters::DirectWriter
      XapianDb.database.size.should == 0
    end

  end

end
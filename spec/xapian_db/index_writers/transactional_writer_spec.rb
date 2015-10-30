# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::TransactionalWriter do

  before :each do
    XapianDb.setup do |config|
      config.adapter  :generic
      config.database :memory
      config.writer   :direct
    end
    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :id
      blueprint.attribute :text
    end
  end

  let(:object) {
    obj = IndexedObject.new(1)
    allow(obj).to receive(:text).and_return("Some text")
    obj
  }
  let(:writer) { XapianDb::IndexWriters::TransactionalWriter.new }

  describe "#index(obj)" do
    it "registers an index request for an object" do
      writer.index object
      expect(writer.index_requests.size).to eq(1)
    end
  end

  describe "#delete_doc_with(xapian_id)" do

    it "registers an index request for an object" do
      writer.delete_doc_with object.xapian_id
      expect(writer.delete_requests.size).to eq(1)
    end
  end

  describe "#reindex(klass)" do

    it "should raise a 'not supported' exception" do
      expect { writer.reindex_class IndexedObject }.to raise_error "rebuild_xapian_index is not supported in transactions"
    end

  end

  describe "#commit_using(writer)" do

    it "commits the index requests to the database", :working => true do
      writer.index object
      expect(XapianDb.database.size).to eq(0) # not commited yet
      writer.commit_using XapianDb::IndexWriters::DirectWriter
      expect(XapianDb.database.size).to eq(1)
    end

    it "commits the delete requests to the database" do
      XapianDb::IndexWriters::DirectWriter.index object
      expect(XapianDb.database.size).to eq(1)
      writer.delete_doc_with object.xapian_id
      expect(XapianDb.database.size).to eq(1) # not commited yet
      writer.commit_using XapianDb::IndexWriters::DirectWriter
      expect(XapianDb.database.size).to eq(0)
    end

  end

end
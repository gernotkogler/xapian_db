# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::DirectWriter do

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
    @obj = IndexedObject.new(1)
    allow(@obj).to receive(:text).and_return("Some text")
  end

  describe ".index(obj)" do
    it "adds an object to the index" do
      expect(XapianDb.database.size).to eq(0)
      XapianDb::IndexWriters::DirectWriter.index @obj
      expect(XapianDb.database.size).to eq(1)
    end
  end

  describe ".delete_doc_with(xapian_id)" do
    it "removes a document from the index" do
      expect(XapianDb.database.size).to eq(0)
      XapianDb::IndexWriters::DirectWriter.index @obj
      expect(XapianDb.database.size).to eq(1)
      XapianDb::IndexWriters::DirectWriter.delete_doc_with @obj.xapian_id
      expect(XapianDb.database.size).to eq(0)
    end
  end

  describe ".reindex(klass)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter  :datamapper
        config.database :memory
        config.writer   :direct
      end
      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
      end
      @obj = DatamapperObject.new(1, "Kogler")
      @obj.save
    end

    it "adds all instances of a class to the index" do
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject
      expect(XapianDb.database.size).to eq(1)
    end

    it "accepts a verbose option" do
      # For full coverage the progressbar gem should be installed
      begin
        require 'ruby-progressbar'
      rescue
      end
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject, :verbose => true
      expect(XapianDb.database.size).to eq(1)
    end

    it "adds all instances of a class to the index" do
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject
      expect(XapianDb.database.size).to eq(1)
    end

    it "uses the blueprint base query if specified" do
      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
        blueprint.base_query { DatamapperObject }
      end
      expect(XapianDb::DocumentBlueprint.blueprint_for(:DatamapperObject).lazy_base_query).to receive(:call).and_return DatamapperObject
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject
    end
  end
end

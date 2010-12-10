# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::DirectWriter do

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
    @obj = IndexedObject.new(1)
    @obj.stub!(:text).and_return("Some text")
  end

  describe ".index(obj)" do
    it "adds an object to the index" do
      XapianDb.database.size.should == 0
      XapianDb::IndexWriters::DirectWriter.index @obj
      XapianDb.database.size.should == 1
    end
  end

  describe ".unindex(obj)" do
    it "removes an object from the index" do
      XapianDb.database.size.should == 0
      XapianDb::IndexWriters::DirectWriter.index @obj
      XapianDb.database.size.should == 1
      XapianDb::IndexWriters::DirectWriter.unindex @obj
      XapianDb.database.size.should == 0
    end
  end

  describe ".reindex(klass)" do

    before :each do
      XapianDb::DocumentBlueprint.setup(DatamapperObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
      end
      @obj = DatamapperObject.new(1, "Kogler")
      @obj.save
    end

    it "adds all instances of a class to the index" do
      XapianDb.database.size.should == 0
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject
      XapianDb.database.size.should == 1
    end

    it "accepts a verbose option" do
      # For full coverage the progressbar gem should be installed
      begin
        require 'progressbar'
      rescue
      end
      XapianDb.database.size.should == 0
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject, :verbose => true
      XapianDb.database.size.should == 1
    end

  end

end
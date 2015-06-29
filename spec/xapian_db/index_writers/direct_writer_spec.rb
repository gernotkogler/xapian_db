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
    @obj.stub!(:text).and_return("Some text")
  end

  describe ".index(obj)" do
    it "adds an object to the index" do
      XapianDb.database.size.should == 0
      XapianDb::IndexWriters::DirectWriter.index @obj
      XapianDb.database.size.should == 1
    end

    it "should (re)index a dependent object if necessary" do
      source_object    = ActiveRecordObject.new 1, 'Müller'
      dependent_object = ActiveRecordObject.new 1, 'Meier'

      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name

        # doesn't make a lot of sense to declare a circular dependency but for this spec it doesn't matter
        blueprint.dependency :ActiveRecordObject, when_changed: %i(name) do |person|
          [dependent_object]
        end
      end
      source_object.stub!(:previous_changes).and_return({ 'name' => 'something' })
      XapianDb::IndexWriters::DirectWriter.should_receive(:reindex).with dependent_object, true
      XapianDb::IndexWriters::DirectWriter.index source_object
    end
  end

  describe ".delete_doc_with(xapian_id)" do
    it "removes a document from the index" do
      XapianDb.database.size.should == 0
      XapianDb::IndexWriters::DirectWriter.index @obj
      XapianDb.database.size.should == 1
      XapianDb::IndexWriters::DirectWriter.delete_doc_with @obj.xapian_id
      XapianDb.database.size.should == 0
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
      XapianDb.database.size.should == 1
    end

    it "accepts a verbose option" do
      # For full coverage the progressbar gem should be installed
      begin
        require 'ruby-progressbar'
      rescue
      end
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject, :verbose => true
      XapianDb.database.size.should == 1
    end

    it "adds all instances of a class to the index" do
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject
      XapianDb.database.size.should == 1
    end

    it "uses the blueprint base query if specified" do
      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
        blueprint.base_query { DatamapperObject }
      end
      XapianDb::DocumentBlueprint.blueprint_for(:DatamapperObject).lazy_base_query.should_receive(:call).and_return DatamapperObject
      XapianDb::IndexWriters::DirectWriter.reindex_class DatamapperObject
    end

  end

end

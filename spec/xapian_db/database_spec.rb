# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Database do

  describe ".store_doc(doc)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :text
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
      @obj       = IndexedObject.new(1)
      @obj.stub!(:text).and_return("Some Text")
      @doc       = @indexer.build_document_for(@obj)
    end

    it "should store the document in the database" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.commit
      XapianDb.database.size.should == 1
    end

    it "must replace a document if the object is already indexed" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.commit
      XapianDb.database.size.should == 1
    end

  end

  describe ".delete_doc_with_unique_term(term)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :text
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
      @obj       = IndexedObject.new(1)
      @obj.stub!(:text).and_return("Some Text")
      @doc       = @indexer.build_document_for(@obj)
    end

    it "should delete the document with this term in the database" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.commit
      XapianDb.database.size.should == 1
      XapianDb.database.delete_doc_with_unique_term(@doc.data).should be_true
      XapianDb.database.commit
      XapianDb.database.size.should == 0
    end

  end

  describe ".delete_docs_of_class(klass)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
    end

    it "should delete all docs of the given class" do

      # Create two test objects we will delete later
      obj = IndexedObject.new(1)
      doc = @indexer.build_document_for(obj)
      XapianDb.database.store_doc(doc).should be_true
      obj = IndexedObject.new(2)
      doc = @indexer.build_document_for(obj)
      XapianDb.database.store_doc(doc).should be_true
      XapianDb.database.commit
      XapianDb.database.size.should == 2

      # Now delete all docs of IndexedObject
      XapianDb.database.delete_docs_of_class(IndexedObject)
      XapianDb.database.commit
      XapianDb.database.size.should == 0

    end

    it "must not delete docs of a different class that have a term like the name of <klass>" do

      class LeaveMeAlone
        attr_reader :id, :text

        def initialize(id, text)
          @id, @text = id, text
        end
      end

      XapianDb::DocumentBlueprint.setup(LeaveMeAlone) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :text
      end

      # Create two test objects we will delete later
      obj = IndexedObject.new(1)
      doc = @indexer.build_document_for(obj)
      XapianDb.database.store_doc(doc).should be_true
      obj = IndexedObject.new(2)
      doc = @indexer.build_document_for(obj)
      XapianDb.database.store_doc(doc).should be_true

      # Now create an object of a different class that has a term "IndexedObject"
      leave_me_alone = LeaveMeAlone.new(1, "IndexedObject")
      doc = @indexer.build_document_for(leave_me_alone)
      XapianDb.database.store_doc(doc).should be_true

      XapianDb.database.commit
      XapianDb.database.size.should == 3

      # Now delete all docs of IndexedObject
      XapianDb.database.delete_docs_of_class(IndexedObject)
      XapianDb.database.commit
      XapianDb.database.size.should == 1 # leave_me_alone must still exist

    end

  end

  describe ".size" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
    end

    it "must be 0 for a new database" do
      XapianDb.database.size.should == 0
    end

  end

  describe ".search(expression)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :text
        blueprint.index :text2
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
      @obj       = IndexedObject.new(1)
      @obj.stub!(:text).and_return("Some Text")
      @obj.stub!(:text2).and_return("findme_in_text2")
      @doc       = @indexer.build_document_for(@obj)
    end

    it "should find a stored document" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.search("Some").size.should == 1
    end

    it "should find a stored document with a wildcard expression" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.search("Som*").size.should == 1
    end

    it "should find a stored document with a field expression" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.search("text:findme_in_text2").size.should == 0
      XapianDb.database.search("text2:findme_in_text2").size.should == 1
    end

    it "should provide a spelling correction if a language is configured" do
      # For this spec we need a persistent database since spelling dictionaries
      # are not supported for in memory databases
      test_db = "/tmp/xapian_test"
      db = XapianDb.create_db :path => test_db

      XapianDb.setup do |config|
        config.language :de
      end

      @obj.stub!(:text).and_return("Hallo Nachbar")
      @indexer = XapianDb::Indexer.new(db, @blueprint)
      @doc     = @indexer.build_document_for(@obj)
      db.store_doc(@doc).should be_true
      db.commit
      db.size.should == 1
      result = db.search "Halo Naachbar"
      result.corrected_query.should == "hallo nachbar"

      # clean up
      FileUtils.rm_rf test_db

    end

  end

end

describe XapianDb::InMemoryDatabase do

  before :each do
    XapianDb.setup do |config|
      config.adapter :generic
      config.database :memory
    end
  end

  describe ".size" do

    it "reflects added documents without committing" do
      doc = Xapian::Document.new
      doc.data = "1" # We need data to store the doc
      XapianDb.database.store_doc(doc)
      XapianDb.database.size.should == 1
    end

  end

end

describe XapianDb::PersistentDatabase do

  before :each do
    XapianDb.setup do |config|
      config.adapter :generic
      config.database "/tmp/xapiandb"
    end
  end

  after :each do
    FileUtils.rm_rf "/tmp/xapiandb"
  end

  it "does not reflect added documents without committing" do
    doc = Xapian::Document.new
    doc.data = "1" # We need data to store the doc
    XapianDb.database.store_doc(doc)
    XapianDb.database.size.should == 0
  end

  describe ".commit" do

    it "writes all pending changes to the database" do
      doc = Xapian::Document.new
      doc.data = "1" # We need data to store the doc
      XapianDb.database.store_doc(doc)
      XapianDb.database.size.should == 0
      XapianDb.database.commit
      XapianDb.database.size.should == 1
    end

  end

end
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Database do
  
  describe ".store_doc(doc)" do
    
    before :each do 
      @db = XapianDb.create_db    
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.field :id
        blueprint.field :text
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @obj       = IndexedObject.new(1)
      @obj.stub!(:text).and_return("Some Text")
      @doc       = @blueprint.indexer.build_document_for(@obj)
    end
    
    it "should store the document in the database" do
      @db.store_doc(@doc).should be_true
      @db.commit
      @db.size.should == 1
    end

    it "must replace a document if the object is already indexed" do
      @db.store_doc(@doc).should be_true
      @db.store_doc(@doc).should be_true
      @db.commit
      @db.size.should == 1
    end
    
  end

  describe ".size" do

    before :each do
      @db = XapianDb.create_db    
    end
    
    it "must be 0 for a new database" do
      @db.size.should == 0
    end

  end
  
  describe ".search(expression)" do

    before :each do 
      @db = XapianDb.create_db    
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.text :text
        blueprint.text :text2
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @obj       = IndexedObject.new(1)
      @obj.stub!(:text).and_return("Some Text")
      @obj.stub!(:text2).and_return("findme_in_text2")
      @doc       = @blueprint.indexer.build_document_for(@obj)
    end
          
    it "should find a stored document" do
      @db.store_doc(@doc).should be_true
      @db.search("Some").size.should == 1
    end

    it "should find a stored document with a wildcard expression" do
      @db.store_doc(@doc).should be_true
      @db.search("Som*").size.should == 1
    end

    it "should find a stored document with a field expression" do
      @db.store_doc(@doc).should be_true
      @db.search("text:findme_in_text2").size.should == 0
      @db.search("text2:findme_in_text2").size.should == 1
    end
    
  end
  
end

describe XapianDb::InMemoryDatabase do
  
  before :each do
    @db = XapianDb.create_db    
  end

  describe ".size" do

    before :each do
      @db = XapianDb.create_db    
    end
    
    it "reflects added documents without committing" do
      doc = Xapian::Document.new
      doc.data = "1" # We need data to store the doc
      @db.store_doc(doc)
      @db.size.should == 1
    end

  end
    
end

describe XapianDb::PersistentDatabase do
  
  before :each do
    GC.start # Since we create a new persistent database for each spec, we 
             # need the GC to release any pending write locks to the database
    @db = XapianDb.create_db :path => "/tmp/xapiandb"
  end

  after :all do
    FileUtils.rm_rf "/tmp/xapiandb"
  end

  it "does not reflect added documents without committing" do
    doc = Xapian::Document.new
    doc.data = "1" # We need data to store the doc
    @db.store_doc(doc)
    @db.size.should == 0
  end

  describe ".commit" do
    
    it "writes all pending changes to the database" do
      doc = Xapian::Document.new
      doc.data = "1" # We need data to store the doc
      @db.store_doc(doc)
      @db.size.should == 0
      @db.commit
      @db.size.should == 1
    end
    
  end
  
end
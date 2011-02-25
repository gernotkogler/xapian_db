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

    it "should return an empty resultset for nil as the search argument" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.search(nil).size.should == 0
    end

    it "should return an empty resultset for an empty string as the search argument" do
      XapianDb.database.store_doc(@doc).should be_true
      XapianDb.database.search(" ").size.should == 0
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

    context "spelling correction" do
      # For these specs we need a persistent database since spelling dictionaries
      # are not supported for in memory databases
      let(:test_db) { test_db = "/tmp/xapian_test" }
      let(:db) { XapianDb.create_db :path => test_db }
      before(:each) do
        XapianDb.setup do |config|
          config.language :de
        end
        @indexer = XapianDb::Indexer.new(db, @blueprint)
      end

      after(:each) do
        # clean up
        FileUtils.rm_rf test_db
      end

      it "should provide a spelling correction if a language is configured" do
        @obj.stub!(:text).and_return("Hallo Nachbar")
        @doc     = @indexer.build_document_for(@obj)
        db.store_doc(@doc).should be_true
        db.commit
        db.size.should == 1
        result = db.search "Halo Naachbar"
        result.spelling_suggestion.should == "hallo nachbar"
      end

      it "should provide correction with the right encoding" do
        @obj.stub!(:text).and_return("Tschüs")
        @doc = @indexer.build_document_for(@obj)
        db.store_doc(@doc)
        db.commit
        result = db.search "stchüs"
        result.spelling_suggestion.should == "tschüs"
      end
    end

    context "sorting" do

      before :each do
        XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
          blueprint.attribute :text
          blueprint.attribute :text2
        end
        obj = IndexedObject.new(1)
        obj.stub!(:text).and_return("same_sort")
        obj.stub!(:text2).and_return("B text")
        doc = @indexer.build_document_for(obj)
        XapianDb.database.store_doc doc
        obj2 = IndexedObject.new(2)
        obj2.stub!(:text).and_return("same_sort")
        obj2.stub!(:text2).and_return("A text")
        doc = @indexer.build_document_for(obj2)
        XapianDb.database.store_doc doc

      end
      it "does not accept the :sort_index option for a query that is not scoped to a class" do
        lambda{XapianDb.search "text", :sort_indices => 1}.should raise_error ArgumentError
      end

      it "accepts the :sort_indices option for a query that is scoped to a class" do
        result = XapianDb.database.search "indexed_class:indexedobject and text", :sort_indices => [2]
        result.size.should == 2
        result.first.text2.should == "A text"
        result.last.text2.should == "B text"
      end

      it "accepts the :sort_decending option for a query that is scoped to a class" do
        result = XapianDb.database.search "indexed_class:indexedobject and text", :sort_indices => [1], :sort_decending => true
        result.size.should == 2
        result.first.text2.should == "B text"
        result.last.text2.should == "A text"
      end

      it "accepts multiple indices for the :sort_indices option" do
        result = XapianDb.database.search "indexed_class:indexedobject and text", :sort_indices => [1, 2]
        result.size.should == 2
        result.first.text2.should == "A text"
        result.last.text2.should == "B text"
      end

    end
  end

  describe ".facets(expression)" do

    before :all do

      class ClassA
        attr_reader :id, :text
        def initialize(id, text)
          @id, @text = id, text
        end
      end

      class ClassB < ClassA
      end

      XapianDb.setup do |config|
        config.adapter  :generic
        config.database :memory
        config.language :en
      end

      XapianDb::DocumentBlueprint.setup(ClassA) do |blueprint|
        blueprint.index :text
      end
      XapianDb::DocumentBlueprint.setup(ClassB) do |blueprint|
        blueprint.index :text
      end

      db = XapianDb.database
      indexerA = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(ClassA)
      indexerB = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(ClassB)

      # We add the name of the other class to the index to make sure we do not find it
      # only by the name of the class
      @objA = ClassA.new(1, "find me classb")
      db.store_doc indexerA.build_document_for(@objA)
      @objB = ClassB.new(1, "find me classa")
      db.store_doc indexerB.build_document_for(@objB)

      XapianDb::Adapters::BaseAdapter.add_class_helper_methods_to ClassA
      XapianDb::Adapters::BaseAdapter.add_class_helper_methods_to ClassB

    end

    it "should return a hash containing the class facets" do
      facets = XapianDb.database.facets "find me"
      facets.size.should == 2
      facets[ClassA].should == 1
      facets[ClassB].should == 1
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

# encoding: utf-8

# Theses specs describe and test the helper methods that are added to indexed classes
# by the active_record adapter
# @author Gernot Kogler

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Adapters::BaseAdapter do

  describe ".add_class_helper_methods_to(klass)" do

    it "adds a class method to search for objects of a specific class" do
      XapianDb::Adapters::BaseAdapter.add_class_helper_methods_to PersistentObject
      PersistentObject.should respond_to :search
    end
  end

  describe ".search(expression)" do

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
        config.database "/tmp/xapian_test"
        config.language :en
      end

      XapianDb::DocumentBlueprint.setup(:ClassA) do |blueprint|
        blueprint.index :text
      end
      XapianDb::DocumentBlueprint.setup(:ClassB) do |blueprint|
        blueprint.index :text
      end

      db = XapianDb.database
      indexerA = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:ClassA)
      indexerB = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:ClassB)

      # We add the name of the other class to the index to make sure we do not find it
      # only by the name of the class
      @objA = ClassA.new(1, "find me classb")
      db.store_doc indexerA.build_document_for(@objA)
      @objB = ClassB.new(1, "find me classa")
      db.store_doc indexerB.build_document_for(@objB)
      db.commit

      XapianDb::Adapters::BaseAdapter.add_class_helper_methods_to ClassA
      XapianDb::Adapters::BaseAdapter.add_class_helper_methods_to ClassB

    end

    after :all do
      FileUtils.rm_rf "/tmp/xapiandb"
    end

    it "should only find objects of a given class" do
      XapianDb.database.search("find me").size.should == 2
      result = ClassA.search("find me")
      result.size.should == 1
      result.first.indexed_class.should == "ClassA"
    end

    it "should remove the class scope from a spelling suggestion" do
      result = ClassA.search("find mee")
      result.spelling_suggestion.should == "find me"
    end

    it "should handle empty search expressions" do
      ClassA.search(nil).size.should == 0
      ClassA.search(" ").size.should == 0
    end

    context "sorting" do

      before :each do
        XapianDb::DocumentBlueprint.setup(:ClassA) do |blueprint|
          blueprint.attribute :text
        end
        indexer = XapianDb::Indexer.new XapianDb.database, XapianDb::DocumentBlueprint.blueprint_for(:ClassA)
        obj1 = ClassA.new(1, "B text")
        XapianDb.database.store_doc indexer.build_document_for(obj1)
        obj2 = ClassA.new(2, "A text")
        XapianDb.database.store_doc indexer.build_document_for(obj2)
        XapianDb.database.commit
      end

      it "should raise an argument error if the :order option contains an unknown attribute" do
        lambda { ClassA.search "text", :order => :unkown }.should raise_error ArgumentError
      end

      it "should accept an :order option" do
        result = ClassA.search "text", :order => :text
        result.first.text.should == "A text"
        result.last.text.should == "B text"
      end

      it "should accept an :sort_decending option" do
        result = ClassA.search "text", :order => :text, :sort_decending => true
        result.first.text.should == "B text"
        result.last.text.should == "A text"
      end

    end

    describe ".find_similar_to(xapian_docs, options)" do

      before :each do

        XapianDb.setup do |config|
          config.adapter  :generic
          config.database :memory
          config.language :en
        end

        XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
          blueprint.attribute :text
        end
        indexer = XapianDb::Indexer.new XapianDb.database, XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
        obj = IndexedObject.new(1)
        obj.stub!(:text).and_return "some text"

        XapianDb.database.store_doc indexer.build_document_for(obj)
        XapianDb.database.commit
      end

      it "delegates the search to the database with a class option" do
        result = IndexedObject.search "some text"
        XapianDb.database.should_receive(:find_similar_to).with(result, :class => IndexedObject)
        IndexedObject.find_similar_to result
      end
    end

    describe ".facets(attribute, expression)" do

      let (:db) { XapianDb.database }

      before :all do

        XapianDb.setup do |config|
          config.adapter  :generic
          config.database :memory
          config.language :en
        end

        XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
          blueprint.attribute :text
        end

        db = XapianDb.database
        indexer = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
        obj = IndexedObject.new(1)
        obj.stub!(:text).and_return "Facet A"
        db.store_doc indexer.build_document_for(obj)
        obj = IndexedObject.new(2)
        obj.stub!(:text).and_return "Facet B"
        db.store_doc indexer.build_document_for(obj)
        XapianDb::Adapters::BaseAdapter.add_class_helper_methods_to IndexedObject
      end

      it "should return a hash containing the values of the attributes and their count" do
        facets = IndexedObject.facets :text, "facet"
        facets.size.should == 2
        facets["Facet A"].should == 1
        facets["Facet B"].should == 1
      end

      it "scopes the facet query to the containing class" do
        XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
          blueprint.attribute :text
        end
        indexer = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:OtherIndexedObject)
        obj = OtherIndexedObject.new(1)
        obj.stub!(:text).and_return "Facet C"
        db.store_doc indexer.build_document_for(obj)

        facets = IndexedObject.facets :text, "facet"
        facets.keys.should_not include("Facet C")
      end

    end

  end

end
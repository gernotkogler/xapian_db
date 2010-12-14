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
      result.paginate.first.indexed_class.should == "ClassA"
    end

    it "should remove the class scope from a spelling suggestion" do
      XapianDb.database.search("find me").size.should == 2
      result = ClassA.search("find mee")
      result.spelling_suggestion.should == "find me"
    end

  end

end
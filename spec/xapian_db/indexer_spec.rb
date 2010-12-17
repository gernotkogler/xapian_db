# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Indexer do

  describe ".xapian_document" do

    before :each do

      XapianDb.setup do |config|
        config.language :none
      end
      @db = XapianDb.create_db

      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :array
        blueprint.attribute :id
        blueprint.attribute :no_value
        blueprint.attribute :text

        blueprint.index :array
        blueprint.index :text
      end

      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @obj       = IndexedObject.new(1)
      @obj.stub!(:text).and_return("Some Text")
      @obj.stub!(:no_value).and_return(nil)
      @obj.stub!(:array).and_return([1, "two", Date.today])
      @indexer = XapianDb::Indexer.new(@db, @blueprint)
      @doc     = @indexer.build_document_for(@obj)
    end

    it "creates a Xapian::Document from an configured object" do
      @indexer.build_document_for(@obj).should be_a_kind_of(Xapian::Document)
    end

    it "inserts the xapian_id into the data property of the Xapian::Document" do
      @doc.data.should == @obj.xapian_id
    end

    it "adds the class name of the object as the first value" do
      @doc.values[0].value.should == @obj.class.name
    end

    it "adds values for the configured methods" do
      @doc.values[2].value.should == @obj.id.to_yaml
      @doc.values[4].value.should == "Some Text".to_yaml
    end

    it "adds terms for the configured methods" do
      @doc.terms.map(&:term).should include("some")
      @doc.terms.map(&:term).should include("text")
      @doc.terms.map(&:term).should include("1") # from the array field
      @doc.terms.map(&:term).should include("two") # from the array field
    end

    it "handles fields with nil values" do
      @doc.values[3].value.should == nil.to_yaml
    end

    it "handles fields with an array as the value" do
      @doc.values[1].value.should == [1, "two", Date.today].to_yaml
    end

    it "uses a stemmer if globally configured" do
      @obj.stub!(:text).and_return("kochen")
      doc = @indexer.build_document_for(@obj)
      doc.terms.map(&:term).should_not include "Zkoch"

      # Now we set the language to german and test the generated terms
      XapianDb.setup do |config|
        config.language :de
      end
      doc = @indexer.build_document_for(@obj)
      doc.terms.map(&:term).should include "Zkoch"
    end

    it "evaluates a block for an attribute if specified" do
      XapianDb.setup do |config|
        config.language :de
      end
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.attribute :complex do
          if @id == 0
            "zero"
          else
            "not zero"
          end
        end
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @indexer = XapianDb::Indexer.new(@db, @blueprint)
      doc = @indexer.build_document_for(@obj)
      doc.values[1].value.should == "not zero".to_yaml
      (doc.terms.map(&:term) & %w(not zero)).should == %w(not zero)
    end

    it "evaluates a block for an index method if specified" do
      XapianDb.setup do |config|
        config.language :de
      end
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.index :complex do
          if @id == 0
            "zero"
          else
            "not zero"
          end
        end
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @indexer = XapianDb::Indexer.new(@db, @blueprint)
      doc = @indexer.build_document_for(@obj)
      (doc.terms.map(&:term) & %w(not zero)).should == %w(not zero)
    end

  end

end
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Indexer do

  describe ".xapian_document" do

    before :each do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.field :id
        blueprint.field :text
        blueprint.field :no_value
        blueprint.field :array

        blueprint.text :text
        blueprint.text :array
      end
      
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(IndexedObject)
      @obj       = IndexedObject.new(1)
      @obj.stub!(:text).and_return("Some Text")
      @obj.stub!(:no_value).and_return(nil)
      @obj.stub!(:array).and_return([1, "two", Date.today])
      @doc       = @blueprint.indexer.build_document_for(@obj)
    end
        
    it "creates a Xapian::Document from an configured object" do
      XapianDb::Indexer.new(@blueprint).build_document_for(@obj).should be_a_kind_of(Xapian::Document)
    end

    it "inserts the xapian_id into the data property of the Xapian::Document" do
      @doc.data.should == @obj.xapian_id
    end

    it "adds the class name of the object as the first value" do
      @doc.values[0].value.should == @obj.class.name
    end

    it "adds values for the configured methods" do
      @doc.values[1].value.should == @obj.id.to_yaml
      @doc.values[2].value.should == "Some Text".to_yaml
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
      @doc.values[4].value.should == [1, "two", Date.today].to_yaml
    end
    
  end
    
end
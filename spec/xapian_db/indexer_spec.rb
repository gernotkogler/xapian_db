# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Indexer do

  before { XapianDb::DocumentBlueprint.reset }

  describe "#build_document_for(obj)" do

    before :each do

      XapianDb.setup do |config|
        config.language :none
      end
      @db = XapianDb.create_db

      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :array, as: :json
        blueprint.attribute :id, as: :integer
        blueprint.attribute :no_value
        blueprint.attribute :text

        blueprint.index :array
        blueprint.index :text
      end

      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      @obj       = IndexedObject.new(1)
      allow(@obj).to receive(:text).and_return("Some Text")
      allow(@obj).to receive(:no_value).and_return(nil)
      allow(@obj).to receive(:array).and_return([1, "two", Date.today])
      @indexer = XapianDb::Indexer.new(@db, @blueprint)
      @doc     = @indexer.build_document_for(@obj)

      @position_offset = 2 # slots 0 and 1 are reserved
    end

    it "creates a Xapian::Document from an configured object" do
      expect(@doc).to be_a_kind_of(Xapian::Document)
    end

    it "inserts the xapian_id into the data property of the Xapian::Document" do
      expect(@doc.data).to eq(@obj.xapian_id)
    end

    it "adds the class name of the object as the first value" do
      expect(@doc.values[0].value).to eq(@obj.class.name)
    end

    it "adds values for the configured methods" do
      expect(@doc.values[@position_offset + 1].value).to eq(Xapian::sortable_serialise(@obj.id))
      expect(@doc.values[@position_offset + 2].value).to eq("Some Text")
    end

    it "adds terms for the configured methods" do
      expect(@doc.terms.map(&:term)).to include("some")
      expect(@doc.terms.map(&:term)).to include("text")
      expect(@doc.terms.map(&:term)).to include("1") # from the array field
      expect(@doc.terms.map(&:term)).to include("two") # from the array field
    end

    it "does not add a value for a filed containing nil" do
      expect(@doc.values[@position_offset + 3]).not_to be
    end

    it "serializes arrays as jason, if specified" do
      expect(@doc.values[@position_offset].value).to eq([1, "two", Date.today].to_json)
    end

    it "uses a stemmer if globally configured" do
      allow(@obj).to receive(:text).and_return("kochen")
      doc = @indexer.build_document_for(@obj)
      expect(doc.terms.map(&:term)).not_to include "Zkoch"

      # Now we set the language to german and test the generated terms
      XapianDb.setup do |config|
        config.language :de
      end
      doc = @indexer.build_document_for(@obj)
      expect(doc.terms.map(&:term)).to include "Zkoch"
    end

    it "evaluates a block for an attribute if specified" do
      XapianDb.setup do |config|
        config.language :de
      end
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :complex do
          if @id == 0
            "zero"
          else
            "not zero"
          end
        end
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      @indexer = XapianDb::Indexer.new(@db, @blueprint)
      doc = @indexer.build_document_for(@obj)
      expect(doc.values[@position_offset].value).to eq("not zero")
      expect(doc.terms.map(&:term) & %w(not zero)).to eq(%w(not zero))
    end

    it "evaluates a block for an index method if specified" do
      XapianDb.setup do |config|
        config.language :de
      end
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :complex do
          if @id == 0
            "zero"
          else
            "not zero"
          end
        end
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      @indexer = XapianDb::Indexer.new(@db, @blueprint)
      doc = @indexer.build_document_for(@obj)
      expect(doc.terms.map(&:term) & %w(not zero)).to eq(%w(not zero))
    end

    it "calls the natural sort order block if present" do
      XapianDb::DocumentBlueprint.reset
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.natural_sort_order do
          "fixed"
        end
      end
      blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj       = IndexedObject.new(1)
      indexer   = XapianDb::Indexer.new(@db, @blueprint)
      doc       = indexer.build_document_for(obj)
      expect(doc.values[1].value).to eq("fixed")
    end

  end

  it "can handle attribute objects that return nil on to_s" do
    XapianDb.setup do |config|
      config.language :none
    end
    @db = XapianDb.create_db

    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :strange_object
    end

    @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    @obj       = IndexedObject.new(1)
    allow(@obj).to receive(:strange_object).and_return ObjectReturningNilOnToS.new
    @indexer = XapianDb::Indexer.new(@db, @blueprint)

    doc = @indexer.build_document_for(@obj)
    expect(doc.terms.size).to eq(3) # The tree terms we always add to a document
  end

  it "respects the term min length option" do
    XapianDb.setup do |config|
      config.term_min_length 2
    end
    @db = XapianDb.create_db

    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :text
    end

    @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    @obj       = IndexedObject.new(1)
    allow(@obj).to receive(:text).and_return "1 xy"
    @indexer = XapianDb::Indexer.new(@db, @blueprint)

    doc = @indexer.build_document_for(@obj)
    expect(doc.terms.map(&:term)).not_to include "1"
  end

  it "does generate a prefixed term if the prefixed option is not set" do
    XapianDb.setup do |config|
      config.term_min_length 2
    end
    @db = XapianDb.create_db

    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :text
    end

    @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    @obj       = IndexedObject.new(1)
    allow(@obj).to receive(:text).and_return "xy"
    @indexer = XapianDb::Indexer.new(@db, @blueprint)

    doc = @indexer.build_document_for(@obj)
    expect(doc.terms.map(&:term)).to include "XTEXTxy"
  end

  it "does generate a prefixed term if the prefixed option is set to true" do
    XapianDb.setup do |config|
      config.term_min_length 2
    end
    @db = XapianDb.create_db

    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :text, prefixed: true
    end

    @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    @obj       = IndexedObject.new(1)
    allow(@obj).to receive(:text).and_return "xy"
    @indexer = XapianDb::Indexer.new(@db, @blueprint)

    doc = @indexer.build_document_for(@obj)
    expect(doc.terms.map(&:term)).to include "XTEXTxy"
  end

  it "does not generate a prefixed term if the prefixed option is false" do
    XapianDb.setup do |config|
      config.term_min_length 2
    end
    @db = XapianDb.create_db

    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :text, prefixed: false
    end

    @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    @obj       = IndexedObject.new(1)
    allow(@obj).to receive(:text).and_return "xy"
    @indexer = XapianDb::Indexer.new(@db, @blueprint)

    doc = @indexer.build_document_for(@obj)
    expect(doc.terms.map(&:term)).not_to include "XTEXTxy"
  end

  it "splits each term if split_term_count != 0" do
    XapianDb.setup do |config|
      config.term_splitter_count 2
    end
    @db = XapianDb.create_db

    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :text, prefixed: false
    end

    @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    @obj       = IndexedObject.new(1)
    allow(@obj).to receive(:text).and_return "test"
    @indexer = XapianDb::Indexer.new(@db, @blueprint)

    doc = @indexer.build_document_for(@obj)
    expect(doc.terms.map(&:term)[3..-1]).to eq(%w(t te test))
  end

  it "does not split each term if split_term_count != 0 but the no_split-option is set on the attribute" do
    XapianDb.setup do |config|
      config.term_splitter_count 2
    end
    @db = XapianDb.create_db

    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :text, prefixed: false, no_split: true
    end

    @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
    @obj       = IndexedObject.new(1)
    allow(@obj).to receive(:text).and_return "test"
    @indexer = XapianDb::Indexer.new(@db, @blueprint)

    doc = @indexer.build_document_for(@obj)
    expect(doc.terms.map(&:term)[3..-1]).to eq(%w(test))
  end

end

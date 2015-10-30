# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Database do

  describe "#store_doc(doc)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :text
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
      @obj       = IndexedObject.new(1)
      allow(@obj).to receive(:text).and_return("Some Text")
      @doc       = @indexer.build_document_for(@obj)
    end

    it "should store the document in the database" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(1)
    end

    it "must replace a document if the object is already indexed" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(1)
    end

  end

  describe "#delete_doc_with_unique_term(term)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :text
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
      @obj       = IndexedObject.new(1)
      allow(@obj).to receive(:text).and_return("Some Text")
      @doc       = @indexer.build_document_for(@obj)
    end

    it "should delete the document with this term in the database" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(1)
      expect(XapianDb.database.delete_doc_with_unique_term(@doc.data)).to be_truthy
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(0)
    end

  end

  describe "#delete_docs_of_class(klass)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :id
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
    end

    it "should delete all docs of the given class" do

      # Create two test objects we will delete later
      obj = IndexedObject.new(1)
      doc = @indexer.build_document_for(obj)
      expect(XapianDb.database.store_doc(doc)).to be_truthy
      obj = IndexedObject.new(2)
      doc = @indexer.build_document_for(obj)
      expect(XapianDb.database.store_doc(doc)).to be_truthy
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(2)

      # Now delete all docs of IndexedObject
      XapianDb.database.delete_docs_of_class(IndexedObject)
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(0)

    end

    it "must not delete docs of a different class that have a term like the name of <klass>" do

      class LeaveMeAlone
        attr_reader :id, :text

        def initialize(id, text)
          @id, @text = id, text
        end
      end

      XapianDb::DocumentBlueprint.setup(:LeaveMeAlone) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :text
      end

      # Create two test objects we will delete later
      obj = IndexedObject.new(1)
      doc = @indexer.build_document_for(obj)
      expect(XapianDb.database.store_doc(doc)).to be_truthy
      obj = IndexedObject.new(2)
      doc = @indexer.build_document_for(obj)
      expect(XapianDb.database.store_doc(doc)).to be_truthy

      # Now create an object of a different class that has a term "IndexedObject"
      leave_me_alone = LeaveMeAlone.new(1, "IndexedObject")
      doc = @indexer.build_document_for(leave_me_alone)
      expect(XapianDb.database.store_doc(doc)).to be_truthy

      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(3)

      # Now delete all docs of IndexedObject
      XapianDb.database.delete_docs_of_class(IndexedObject)
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(1) # leave_me_alone must still exist

    end

  end

  describe "#size" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
    end

    it "must be 0 for a new database" do
      expect(XapianDb.database.size).to eq(0)
    end

  end

  describe "#search(expression)" do

    before :each do
      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :text
        blueprint.index :text2
      end
      @blueprint = XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      @indexer   = XapianDb::Indexer.new(XapianDb.database, @blueprint)
      @obj       = IndexedObject.new(1)
      allow(@obj).to receive(:text).and_return("Some Text")
      allow(@obj).to receive(:text2).and_return("findme_in_text2")
      @doc       = @indexer.build_document_for(@obj)
    end

    it "should return an empty resultset for nil as the search argument" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      expect(XapianDb.database.search(nil).size).to eq(0)
    end

    it "should return an empty resultset for an empty string as the search argument" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      expect(XapianDb.database.search(" ").size).to eq(0)
    end

    it "should find a stored document" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      expect(XapianDb.database.search("Some").size).to eq(1)
    end

    it "should find a stored document with a wildcard expression" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      expect(XapianDb.database.search("Som*").size).to eq(1)
    end

    it "should find a stored document with a field expression" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy
      expect(XapianDb.database.search("text:findme_in_text2").size).to eq(0)
      expect(XapianDb.database.search("text2:findme_in_text2").size).to eq(1)
    end

    it "should retry if a Xapian::DatabaseModifiedError occurs" do
      expect(XapianDb.database.store_doc(@doc)).to be_truthy

      # first try
      expect(XapianDb::Resultset).to receive(:new).and_raise IOError.new "DatabaseModifiedError: The revision being read has been discarded - you should call Xapian::Database::reopen() and retry the operation"
      # second try
      expect(XapianDb::Resultset).to receive(:new).and_return [1]
      expect(XapianDb.database.search("text2:findme_in_text2").size).to eq(1)
    end

    it "should support phrase searches" do
      XapianDb.setup do |config|
        config.enable_query_flag Xapian::QueryParser::FLAG_PHRASE
      end

      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.index :text
      end
      obj       = IndexedObject.new(1)
      allow(obj).to receive(:text).and_return("This is a complete sentence")
      doc       = @indexer.build_document_for(obj)
      expect(XapianDb.database.store_doc(doc)).to be_truthy

      obj       = IndexedObject.new(2)
      allow(obj).to receive(:text).and_return("This sentence is a complete one")
      doc       = @indexer.build_document_for(obj)
      expect(XapianDb.database.store_doc(doc)).to be_truthy

      expect(XapianDb.database.search('This is a complete sentence').size).to eq(2)
      expect(XapianDb.database.search('"This is a complete sentence"').size).to eq(1)
    end

    describe "spelling correction" do
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
        allow(@obj).to receive(:text).and_return("Hallo Nachbar")
        @doc     = @indexer.build_document_for(@obj)
        expect(db.store_doc(@doc)).to be_truthy
        db.commit
        expect(db.size).to eq(1)
        result = db.search "Halo Naachbar"
        expect(result.spelling_suggestion).to eq("hallo nachbar")
      end

      it "should provide correction with the right encoding" do
        allow(@obj).to receive(:text).and_return("Tschüs")
        @doc = @indexer.build_document_for(@obj)
        db.store_doc(@doc)
        db.commit
        result = db.search "stchüs"
        expect(result.spelling_suggestion).to eq("tschüs")
      end
    end

    describe "sorting" do

      before :each do
        XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
          blueprint.attribute :text
          blueprint.attribute :text2
          blueprint.attribute :number, as: :integer
        end

        obj = IndexedObject.new(1)
        allow(obj).to receive(:text).and_return("same_sort")
        allow(obj).to receive(:text2).and_return("B text")
        allow(obj).to receive(:number).and_return(10)
        doc = @indexer.build_document_for(obj)
        XapianDb.database.store_doc doc
        obj = IndexedObject.new(2)
        allow(obj).to receive(:text).and_return("same_sort")
        allow(obj).to receive(:text2).and_return("A text")
        allow(obj).to receive(:number).and_return(1)
        doc = @indexer.build_document_for(obj)
        XapianDb.database.store_doc doc
      end

      describe "without sort indices" do

        describe "without a natural sort order specified" do

          it "sorts the result by relevance, then id" do
            result = XapianDb.database.search "same_sort"
            expect(result.map { |doc| doc.data.split("-").last.to_i }).to eq([1, 2])
          end

        end

        describe "with a natural sort order specified" do

          before :each do
            XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
              blueprint.attribute :text
              blueprint.natural_sort_order :text
            end

            obj = IndexedObject.new(1)
            allow(obj).to receive(:text).and_return("Text B")
            doc = @indexer.build_document_for(obj)
            XapianDb.database.store_doc doc
            obj = IndexedObject.new(2)
            allow(obj).to receive(:text).and_return("Text A")
            doc = @indexer.build_document_for(obj)
            XapianDb.database.store_doc doc
          end

          it "sorts the result by relevance, then natural sort" do
            result = XapianDb.database.search "Text"
            expect(result.map { |doc| doc.data.split("-").last.to_i }).to eq([2, 1])
          end
        end
      end

      it "accepts the :sort_indices option for a query" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text2)]
        result = XapianDb.database.search "text", :sort_indices => sort_indices
        expect(result.size).to eq(2)
        expect(result.first.text2).to eq("A text")
        expect(result.last.text2).to eq("B text")
      end

      it "accepts the :sort_indices option for a query that is scoped to a class" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text2)]
        result = XapianDb.database.search "indexed_class:indexedobject and text", :sort_indices => sort_indices
        expect(result.size).to eq(2)
        expect(result.first.text2).to eq("A text")
        expect(result.last.text2).to eq("B text")
      end

      it "accepts the :sort_decending option for a query" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text)]
        result = XapianDb.database.search "text", :sort_indices => sort_indices, :sort_decending => true
        expect(result.size).to eq(2)
        expect(result.first.text2).to eq("B text")
        expect(result.last.text2).to eq("A text")
      end

      it "accepts the :sort_decending option for a query that is scoped to a class" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text)]
        result = XapianDb.database.search "indexed_class:indexedobject and text", :sort_indices => sort_indices, :sort_decending => true
        expect(result.size).to eq(2)
        expect(result.first.text2).to eq("B text")
        expect(result.last.text2).to eq("A text")
      end

      it "accepts multiple indices for the :sort_indices option" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text), XapianDb::DocumentBlueprint.value_number_for(:text2)]
        result = XapianDb.database.search "text", :sort_indices => sort_indices
        expect(result.size).to eq(2)
        expect(result.first.text2).to eq("A text")
        expect(result.last.text2).to eq("B text")
      end

      it "accepts multiple indices for the :sort_indices option for a query that is scoped to a class" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text), XapianDb::DocumentBlueprint.value_number_for(:text2)]
        result = XapianDb.database.search "indexed_class:indexedobject and text", :sort_indices => sort_indices
        expect(result.size).to eq(2)
        expect(result.first.text2).to eq("A text")
        expect(result.last.text2).to eq("B text")
      end

      it "orders the result numerically if a number attribute is used for sorting" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:number)]
        result = XapianDb.database.search "text", :sort_indices => sort_indices
        expect(result.size).to eq(2)
        expect(result.first.number).to eq(1)
        expect(result.last.number).to eq(10)
      end

      it "accepts the :order option for a query" do
        # sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text2)]
        result = XapianDb.database.search "text", order: [:text2]
        expect(result.size).to eq(2)
        expect(result.first.text2).to eq("A text")
        expect(result.last.text2).to eq("B text")
      end

      it "raises an argument error if sort_indices and order are both used" do
        sort_indices = [XapianDb::DocumentBlueprint.value_number_for(:text2)]
        expect{ XapianDb.database.search "text", sort_indices: sort_indices, order: [:text2] }.to raise_error "you can't use sort_indices and order, only one of them"
      end

    end
  end

  describe "#facets(expression)" do

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

      indexer = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
      obj = IndexedObject.new(1)
      allow(obj).to receive(:text).and_return "Facet A"
      db.store_doc indexer.build_document_for(obj)
      obj = IndexedObject.new(2)
      allow(obj).to receive(:text).and_return "Facet B"
      db.store_doc indexer.build_document_for(obj)
      XapianDb::Adapters::BaseAdapter.add_class_helper_methods_to IndexedObject
    end

    it "should return a hash containing the values of the attributes and their count" do
      facets = XapianDb.database.facets :text, "facet"
      expect(facets.size).to eq(2)
      expect(facets["Facet A"]).to eq(1)
      expect(facets["Facet B"]).to eq(1)
    end

    it "collects the facets across all indexed classes" do
      XapianDb::DocumentBlueprint.setup(:OtherIndexedObject) do |blueprint|
        blueprint.attribute :text
      end
      indexer = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:OtherIndexedObject)
      obj = OtherIndexedObject.new(1)
      allow(obj).to receive(:text).and_return "Facet C"
      db.store_doc indexer.build_document_for(obj)

      facets = XapianDb.database.facets :text, "facet"
      expect(facets.size).to eq(3)
      expect(facets["Facet A"]).to eq(1)
      expect(facets["Facet B"]).to eq(1)
      expect(facets["Facet C"]).to eq(1)

    end

  end

  describe "#find_similar_to(xapian_docs, options)" do

    before :all do

      class Class
        attr_reader :id, :text
        def initialize(id, text)
          @id, @text = id, text
        end
      end

      XapianDb.setup do |config|
        config.adapter :generic
        config.database :memory
      end

      XapianDb::DocumentBlueprint.setup(:Class) do |blueprint|
        blueprint.index :text
      end

      db = XapianDb.database
      indexer = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:Class)

      obj = Class.new(1, "xapian rocks")
      db.store_doc indexer.build_document_for(obj)

      obj = Class.new(2, "on the rocks")
      db.store_doc indexer.build_document_for(obj)

      obj = Class.new(3, "xapian is cool")
      db.store_doc indexer.build_document_for(obj)

    end

    it "accepts a single xapian document" do
      reference = XapianDb.database.search "xapian rocks"
      expect { XapianDb.database.find_similar_to reference.first }.not_to raise_error
    end

    it "accepts a resultset" do
      reference = XapianDb.database.search "xapian"
      expect { XapianDb.database.find_similar_to reference }.not_to raise_error
    end

    it "returns a resultset" do
      reference = XapianDb.database.search "xapian"
      expect(XapianDb.database.find_similar_to(reference)).to be_a XapianDb::Resultset
    end

    it "does not return the reference document(s)" do
      reference = XapianDb.database.search "xapian rocks"
      result = XapianDb.database.find_similar_to(reference)
      expect(result.detect {|doc| doc.docid == reference.first.docid}).not_to be
    end

    describe "with a class option" do

      before :each do

        class ClassToIgnore
          attr_reader :id, :text
          def initialize(id, text)
            @id, @text = id, text
          end
        end

        XapianDb::DocumentBlueprint.setup(:ClassToIgnore) do |blueprint|
          blueprint.index :text
        end

        db = XapianDb.database
        indexer = XapianDb::Indexer.new db, XapianDb::DocumentBlueprint.blueprint_for(:ClassToIgnore)

        obj = ClassToIgnore.new(1, "xapian is sweet")
        db.store_doc indexer.build_document_for(obj)
      end

      it "should not find documents based on other classes" do
        reference = XapianDb.database.search "xapian rocks"
        result = XapianDb.database.find_similar_to(reference, :class => Class)
        expect(result.detect { |doc| doc.indexed_class != Class.name }).not_to be
      end

    end

    describe "with a limit option" do

      it "respects the limit" do
        reference = XapianDb.database.search "xapian rocks"
        result = XapianDb.database.find_similar_to reference, :limit => 1
        expect(result.size).to eq(1)
      end

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

  describe "#size" do

    it "reflects added documents without committing" do
      doc = Xapian::Document.new
      doc.data = "1" # We need data to store the doc
      XapianDb.database.store_doc(doc)
      expect(XapianDb.database.size).to eq(1)
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
    expect(XapianDb.database.size).to eq(0)
  end

  describe "#commit" do

    it "writes all pending changes to the database" do
      doc = Xapian::Document.new
      doc.data = "1" # We need data to store the doc
      XapianDb.database.store_doc(doc)
      expect(XapianDb.database.size).to eq(0)
      XapianDb.database.commit
      expect(XapianDb.database.size).to eq(1)
    end

  end
end

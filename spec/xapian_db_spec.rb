# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe XapianDb do

  before :each do
    XapianDb::DocumentBlueprint.reset
  end

  describe ".setup(&block)" do

    it "should delegate the setup to the config class" do
      XapianDb.setup do |config|
        config.database :memory
      end
      expect(XapianDb.database).to be_a_kind_of XapianDb::InMemoryDatabase
    end

  end

  describe ".create_db" do

    it "should create an in memory database by default" do
      db = XapianDb.create_db
      expect(db.reader).to be_a_kind_of(Xapian::Database)
      expect(db.writer).to be_a_kind_of(Xapian::Database)
    end

    it "should create a database on disk if a path is given" do
      temp_dir = "/tmp/xapiandb"
      db = XapianDb.create_db(:path => temp_dir)
      expect(db.reader).to be_a_kind_of(Xapian::Database)
      expect(db.writer).to be_a_kind_of(Xapian::WritableDatabase)
      expect(File.exists?(temp_dir)).to be_truthy
      FileUtils.rm_rf temp_dir
    end

  end

  describe ".open_db" do

    it "should open an in memory database by default" do
      db = XapianDb.open_db
      expect(db.reader).to be_a_kind_of(Xapian::Database)
      expect(db.writer).to be_a_kind_of(Xapian::Database)
    end

    it "should open a database on disk if a path is given" do
      # First we create a test database
      temp_dir = "/tmp/xapiandb"
      db = XapianDb.create_db(:path => temp_dir)
      expect(File.exists?(temp_dir)).to be_truthy

      # Now we try to open the created database again
      db = XapianDb.open_db(:path => temp_dir)
      expect(db.reader).to be_a_kind_of(Xapian::Database)
      FileUtils.rm_rf temp_dir
    end

  end

  describe ".search(expression, options={})" do

    before :each do
      XapianDb.setup do |config|
        config.database :memory
      end
    end

    it "should delegate the search to the current database" do
      expect(XapianDb.search("Something")).to be_a_kind_of(XapianDb::Resultset)
    end

    it "accepts per_page and page options" do
      expect(XapianDb.search("Something", :per_page => 10, :page => 1)).to be_a_kind_of(XapianDb::Resultset)
    end

    describe "with an order expression" do

      before :each do
        XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
          blueprint.attribute :text
        end
        indexer = XapianDb::Indexer.new XapianDb.database, XapianDb::DocumentBlueprint.blueprint_for(:IndexedObject)
        obj1 = IndexedObject.new(1)
        allow(obj1).to receive(:text).and_return "A text"
        XapianDb.database.store_doc indexer.build_document_for(obj1)
        obj2 = IndexedObject.new(2)
        allow(obj2).to receive(:text).and_return "B text"
        XapianDb.database.store_doc indexer.build_document_for(obj2)
        XapianDb.database.commit
      end

      it "should raise an argument error if the :order option contains an unknown attribute" do
        expect { XapianDb.search "text", :order => :unkown }.to raise_error ArgumentError
      end

      it "should accept an :order option" do
        result = XapianDb.search "text", :order => :text
        expect(result.first.text).to eq("A text")
        expect(result.last.text).to eq("B text")
      end

      it "should accept an :sort_decending option" do
        result = XapianDb.search "text", :order => :text, :sort_decending => true
        expect(result.first.text).to eq("B text")
        expect(result.last.text).to eq("A text")
      end

    end

  end

  describe ".facets(attribute, expression)" do

    it "should delegate the facets query to the current database" do
      XapianDb.setup do |config|
        config.database :memory
      end
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.attribute :text
      end
      expect(XapianDb.facets(:text, "Something")).to be_a_kind_of(Hash)
    end

  end

  describe ".reindex(obj)" do

    before :each do
      XapianDb.setup do |config|
        config.database :memory
        config.adapter :active_record
        config.writer  :direct
      end

      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name
        blueprint.ignore_if {
          date > Date.today
        }
      end

    end

    it "updates the xapian document belonging to the object" do
      @object = ActiveRecordObject.new(1, "Kogler")
      @object.save
      expect(XapianDb.search("Kogler").size).to eq(1)
      allow(@object).to receive(:name).and_return "renamed"
      XapianDb.reindex(@object)
      expect(XapianDb.search("renamed").size).to eq(1)
    end

    it "deletes the xapian document if the ignore_if clause evaluates to false" do
      @object = ActiveRecordObject.new(1, "Kogler")
      @object.save
      expect(XapianDb.search("Kogler").size).to eq(1)
      @object.date = Date.today + 1
      XapianDb.reindex(@object)
      expect(XapianDb.search("Kogler").size).to eq(0)
    end

  end

  describe ".rebuild_xapian_index" do

    before :each do
      XapianDb.setup do |config|
        config.database :memory
        config.adapter :active_record
        config.writer  :direct
      end
    end

    it "does nothing if no blueprints are configured" do
      XapianDb::DocumentBlueprint.reset
      expect{XapianDb.rebuild_xapian_index}.not_to raise_error
      expect(XapianDb.rebuild_xapian_index).to be_falsey
    end

    it "rebuilds the index for all blueprints" do
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name
      end
      @object = ActiveRecordObject.new(1, "Kogler")
      @object.save

      expect(XapianDb.search("Kogler").size).to eq(1)

      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      expect(XapianDb.search("Kogler").size).to eq(0)

      XapianDb.rebuild_xapian_index
      expect(XapianDb.search("Kogler").size).to eq(1)
    end

    it "ignores blueprints that describe plain ruby classes" do
      XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
        blueprint.adapter :generic
        blueprint.index :id
      end
      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      expect {XapianDb.rebuild_xapian_index}.not_to raise_error
    end

  end

  describe "date ranges" do
    before :each do
      XapianDb.setup do |config|
        config.database :memory
        config.adapter :active_record
        config.writer  :direct
      end
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name
        blueprint.attribute :date, :as => :date
      end
      @object1 = ActiveRecordObject.new(1, "Benjamin", Date.today - 1)
      @object1.save
      @object2 = ActiveRecordObject.new(2, "Benjamin", Date.today)
      @object2.save
      @object3 = ActiveRecordObject.new(3, "Benjamin", Date.today + 1)
      @object3.save
    end

    it "should should get the objects by date" do
      result = XapianDb.search("date:#{Date.today.strftime('%Y-%m-%d')}")
      expect(result.size).to eq(1)
      expect(result.first.data).to eq("ActiveRecordObject-2")
    end

    it "should find all objects with a full range" do
      expect(XapianDb.search("date:#{@object1.date.strftime('%Y-%m-%d')}..#{@object3.date.strftime('%Y-%m-%d')}").size).to eq(3)
    end

    it "should find selection of objects with partial range" do
      expect(XapianDb.search("date:#{@object2.date.strftime('%Y-%m-%d')}..#{@object3.date.strftime('%Y-%m-%d')}").size).to eq(2)
    end

    it "should find selection of objects with open ending range" do
      expect(XapianDb.search("date:#{@object3.date.strftime('%Y-%m-%d')}..").size).to eq(1)
    end

    it "should find selection of objects with open beginning range" do
      expect(XapianDb.search("date:..#{@object2.date.strftime('%Y-%m-%d')}").size).to eq(2)
    end
  end

  describe "number ranges" do
    before :each do
      XapianDb.setup do |config|
        config.database :memory
        config.adapter :active_record
        config.writer  :direct
      end
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name
        blueprint.attribute :age, :as => :number
      end
      @object1 = ActiveRecordObject.new(1, "Gernot", Date.today, 30)
      @object1.save
      @object2 = ActiveRecordObject.new(2, "Gernot", Date.today, 31)
      @object2.save
      @object3 = ActiveRecordObject.new(3, "Gernot", Date.today, 32)
      @object3.save
    end

    it "should should get the objects by number" do
      result = XapianDb.search("age:31")
      expect(result.size).to eq(1)
      expect(result.first.data).to eq("ActiveRecordObject-2")
    end

    it "should find all objects with a full range" do
      expect(XapianDb.search("age:30..32").size).to eq(3)
    end

    it "should find selection of objects with partial range" do
      expect(XapianDb.search("age:31..32").size).to eq(2)
    end

    it "should find selection of objects with open ending range" do
      expect(XapianDb.search("age:32..").size).to eq(1)
    end

    it "should find selection of objects with open beginning range" do
      expect(XapianDb.search("age:..31").size).to eq(2)
    end
  end

  describe "string ranges" do
    before :each do
      XapianDb.setup do |config|
        config.database :memory
        config.adapter :active_record
        config.writer  :direct
      end
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.attribute :name, :as => :string
        blueprint.attribute :age, :as => :number
      end
      @object1 = ActiveRecordObject.new(1, "Adam", Date.today, 30)
      @object1.save
      @object2 = ActiveRecordObject.new(2, "Bernard", Date.today, 31)
      @object2.save
      @object3 = ActiveRecordObject.new(3, "Chris", Date.today, 32)
      @object3.save
    end

    it "should find all objects with a full range" do
      expect(XapianDb.search("name:Adam..Chris").size).to eq(3)
    end

    it "should find selection of objects with partial range" do
      expect(XapianDb.search("name:Bernard..Chris").size).to eq(2)
    end

    it "should find selection of objects with open ending range" do
      expect(XapianDb.search("name:Chris..").size).to eq(1)
    end

    it "should find selection of objects with open beginning range" do
      expect(XapianDb.search("name:..Bernard").size).to eq(2)
    end
  end

  context "transactions" do

    before :each do
      XapianDb.setup do |config|
        config.adapter  :active_record
        config.database :memory
        config.writer   :direct
      end

      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
      end
    end

    let(:object) { ActiveRecordObject.new(1, "Kogler") }

    describe ".transaction(&block)" do

      it "executes the given block" do
        XapianDb.transaction do
          object.save
        end
        expect(XapianDb.database.size).to eq(1)
      end

      it "reraises exceptions" do
        expect { XapianDb.transaction do
          object.save
          raise "oops"
        end }.to raise_error "oops"
      end

      it "does not index the objects saved in the block if the block raises an error" do
        begin
          XapianDb.transaction do
            object.save
            raise "oops"
          end
          rescue
        end
        expect(XapianDb.database.size).to eq(0)
      end

      it "logs exceptions if used within a rails app" do
        Rails = double "Rails"
        logger = double "logger"
        allow(Rails).to receive(:logger).and_return logger
        expect(logger).to receive :error

        begin
          XapianDb.transaction do
            object.save
            raise "oops"
          end
          rescue
        end
        expect(XapianDb.database.size).to eq(0)
      end

    end


    describe "outside a transaction" do

      describe ".index(obj)" do
        it "delegates the request to the configured writer" do
          expect(XapianDb::Config.writer).to receive(:index).once
          XapianDb.index object
        end
      end

      describe ".delete_doc_with(xapian_id)" do
        it "delegates the request to the configured writer" do
          expect(XapianDb::Config.writer).to receive(:delete_doc_with).once
          XapianDb.delete_doc_with object.xapian_id
        end
      end

      describe ".reindex_class(klass)" do
        it "delegates the request to the configured writer" do
          expect(XapianDb::Config.writer).to receive(:reindex_class).once
          XapianDb.reindex_class object.class
        end
      end
    end

  end

  context "no indexing" do

    before :each do
      XapianDb.setup do |config|
        config.adapter  :active_record
        config.database :memory
        config.writer   :direct
      end

      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.attribute :id
        blueprint.attribute :name
      end
    end

    let(:object) { ActiveRecordObject.new(1, "Kogler") }

    describe ".auto_indexing_disabled(&block)" do

      it "executes the given block and does not update the index" do
        XapianDb.auto_indexing_disabled do
          object.save
        end
        expect(XapianDb.database.size).to eq(0)
      end

      it "reraises exceptions" do
        expect { XapianDb.auto_indexing_disabled do
          object.save
          raise "oops"
        end }.to raise_error "oops"
      end

    end
  end
end

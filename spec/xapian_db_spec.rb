# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe XapianDb do

  describe ".setup(&block)" do

    it "should delegate the setup to the config class" do
      XapianDb.setup do |config|
        config.database :memory
      end
      XapianDb.database.should be_a_kind_of XapianDb::InMemoryDatabase
    end

  end

  describe ".create_db" do

    it "should create an in memory database by default" do
      db = XapianDb.create_db
      db.reader.should be_a_kind_of(Xapian::Database)
      db.writer.should be_a_kind_of(Xapian::Database)
    end

    it "should create a database on disk if a path is given" do
      temp_dir = "/tmp/xapiandb"
      db = XapianDb.create_db(:path => temp_dir)
      db.reader.should be_a_kind_of(Xapian::Database)
      db.writer.should be_a_kind_of(Xapian::WritableDatabase)
      File.exists?(temp_dir).should be_true
      FileUtils.rm_rf temp_dir
    end

  end

  describe ".open_db" do

    it "should open an in memory database by default" do
      db = XapianDb.open_db
      db.reader.should be_a_kind_of(Xapian::Database)
      db.writer.should be_a_kind_of(Xapian::Database)
    end

    it "should open a database on disk if a path is given" do
      # First we create a test database
      temp_dir = "/tmp/xapiandb"
      db = XapianDb.create_db(:path => temp_dir)
      File.exists?(temp_dir).should be_true

      # Now we try to open the created database again
      db = XapianDb.open_db(:path => temp_dir)
      db.reader.should be_a_kind_of(Xapian::Database)
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
      XapianDb.search("Something").should be_a_kind_of(XapianDb::Resultset)
    end

    it "accepts per_page and page options" do
      XapianDb.search("Something", :per_page => 10, :page => 1).should be_a_kind_of(XapianDb::Resultset)
    end

  end

  describe ".facets(expression)" do

    it "should delegate the facets query to the current database" do
      XapianDb.setup do |config|
        config.database :memory
      end
      XapianDb.facets("Something").should be_a_kind_of(Hash)
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
      XapianDb::DocumentBlueprint.instance_variable_set(:@blueprints, nil)
      lambda{XapianDb.rebuild_xapian_index}.should_not raise_error
      XapianDb.rebuild_xapian_index.should be_false
    end

    it "rebuilds the index for all blueprints" do
      XapianDb::DocumentBlueprint.setup(ActiveRecordObject) do |blueprint|
        blueprint.index :name
      end
      @object = ActiveRecordObject.new(1, "Kogler")
      @object.save

      XapianDb.search("Kogler").size.should == 1

      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      XapianDb.search("Kogler").size.should == 0

      XapianDb.rebuild_xapian_index
      XapianDb.search("Kogler").size.should == 1
    end

    it "ignores blueprints that describe plain ruby classes" do
      XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
        blueprint.adapter :generic
        blueprint.index :id
      end
      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      lambda {XapianDb.rebuild_xapian_index}.should_not raise_error
    end

  end

  describe "date ranges" do
    before :each do
      XapianDb.setup do |config|
        config.database :memory
        config.adapter :active_record
        config.writer  :direct
      end
      XapianDb::DocumentBlueprint.setup(ActiveRecordObject) do |blueprint|
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
      result.size.should == 1
      result.first.data.should == "ActiveRecordObject-2"
    end

    it "should find all objects with a full range" do
      XapianDb.search("date:#{@object1.date.strftime('%Y-%m-%d')}..#{@object3.date.strftime('%Y-%m-%d')}").size.should == 3
    end

    it "should find selection of objects with partial range" do
      XapianDb.search("date:#{@object2.date.strftime('%Y-%m-%d')}..#{@object3.date.strftime('%Y-%m-%d')}").size.should == 2
    end
    it "should find selection of objects with open ending range" do
      XapianDb.search("date:#{@object3.date.strftime('%Y-%m-%d')}..").size.should == 1
    end
    it "should find selection of objects with open beginning range" do
      XapianDb.search("date:..#{@object2.date.strftime('%Y-%m-%d')}").size.should == 2
    end
  end

  context "transactions" do

    before :each do
      XapianDb.setup do |config|
        config.adapter  :active_record
        config.database :memory
        config.writer   :direct
      end

      XapianDb::DocumentBlueprint.setup(ActiveRecordObject) do |blueprint|
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
        XapianDb.database.size.should == 1
      end

      it "reraises exceptions" do
        lambda { XapianDb.transaction do
          object.save
          raise "oops"
        end }.should raise_error "oops"
      end

      it "does not index the objects saved in the block if the block raises an error" do
        begin
          XapianDb.transaction do
            object.save
            raise "oops"
          end
          rescue
        end
        XapianDb.database.size.should == 0
      end

      it "logs exceptions if used within a rails app" do
        Rails = mock "Rails"
        logger = mock "logger"
        Rails.stub(:logger).and_return logger
        logger.should_receive :error

        begin
          XapianDb.transaction do
            object.save
            raise "oops"
          end
          rescue
        end
        XapianDb.database.size.should == 0
      end

    end


    describe "outside a transaction" do

      describe ".index(obj)" do
        it "delegates the request to the configured writer" do
          XapianDb::Config.writer.should_receive(:index).once
          XapianDb.index object
        end
      end

      describe ".delete_doc_with(xapian_id)" do
        it "delegates the request to the configured writer" do
          XapianDb::Config.writer.should_receive(:delete_doc_with).once
          XapianDb.delete_doc_with object.xapian_id
        end
      end

      describe ".reindex_class(klass)" do
        it "delegates the request to the configured writer" do
          XapianDb::Config.writer.should_receive(:reindex_class).once
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

      XapianDb::DocumentBlueprint.setup(ActiveRecordObject) do |blueprint|
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
        XapianDb.database.size.should == 0
      end

      it "reraises exceptions" do
        lambda { XapianDb.auto_indexing_disabled do
          object.save
          raise "oops"
        end }.should raise_error "oops"
      end

    end
  end
end

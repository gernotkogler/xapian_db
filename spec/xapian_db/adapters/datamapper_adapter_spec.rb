# encoding: utf-8

# Theses specs describe and test the helper methods that are added to indexed classes
# by the datamapper adapter
# @author Gernot Kogler

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Adapters::DatamapperAdapter do

  before :each do
    @db = XapianDb.create_db
    XapianDb::DocumentBlueprint.default_adapter = XapianDb::Adapters::DatamapperAdapter
    XapianDb::Adapters::DatamapperAdapter.database = @db
    XapianDb::DocumentBlueprint.setup(DatamapperObject) do |blueprint|
      blueprint.index :name
    end
    
    @object = DatamapperObject.new(1, "Kogler")
  end
  
  describe ".add_class_helper_methods_to(klass)" do

    it "should raise an exception if no database is configured for the adapter" do
    end

    it "adds the method 'xapian_id' to the configured class" do
      @object.should respond_to(:xapian_id)
    end

    it "adds an after save hook to the configured class" do
      DatamapperObject.hooks[:after_save].should be_a_kind_of(Proc)
    end

    it "adds an after destroy hook to the configured class" do
      DatamapperObject.hooks[:after_destroy].should be_a_kind_of(Proc)
    end

    it "adds a class method to reindex all objects of a class" do
      DatamapperObject.should respond_to(:reindex_xapian_db)
    end

  end

  describe ".add_doc_helper_methods_to(obj)" do
    
    it "adds the method 'indexed_object' to the object" do
      mod = Module.new
      XapianDb::Adapters::DatamapperAdapter.add_doc_helper_methods_to(mod)
      mod.instance_methods.should include(:indexed_object)
    end
    
  end
  
  describe ".xapian_id" do
    it "returns a unique id composed of the class name and the id" do
      @object.xapian_id.should == "#{@object.class}-#{@object.id}"
    end
  end
  
  describe "the after save hook" do
    it "should (re)index the object" do
      @object.save
      @db.search("Kogler").paginate.size.should == 1
    end
  end

  describe "the after destroy hook" do
    it "should remove the object from the index" do
      @object.save
      @db.search("Kogler").paginate.size.should == 1
      @object.destroy
      @db.search("Kogler").paginate.size.should == 0
    end
  end

  describe ".indexed_object" do
    
    it "should return the object that is linked with the document" do
      @object.save
      doc = @db.search("Kogler").paginate.first
      doc.indexed_object.should be_equal(@object)
    end
    
  end
  
  describe ".reindex_xapian_db" do
    it "should (re)index all objects of this class" do
      @object.save
      @db.search("Kogler").size.should == 1

      # We reopen the in memory database to destroy the index
      @db = XapianDb.create_db
      XapianDb::Adapters::DatamapperAdapter.database = @db
      @db.search("Kogler").size.should == 0
            
      DatamapperObject.reindex_xapian_db
      @db.commit
      @db.search("Kogler").size.should == 1
    end
  end
    
end
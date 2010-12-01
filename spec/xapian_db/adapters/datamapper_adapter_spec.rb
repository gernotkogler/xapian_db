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
  
  describe ".add_helper_methods_to(klass)" do

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
    
end
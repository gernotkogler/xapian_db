# encoding: utf-8

# Theses specs describe and test the helper methods that are added to indexed classes
# by the datamapper adapter
# @author Gernot Kogler

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::Adapters::DatamapperAdapter do

  before :each do
    XapianDb.setup do |config|
      config.database :memory
      config.adapter :datamapper
      config.writer  :direct
    end
    XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
      blueprint.index :name
    end

    @object = DatamapperObject.new(1, "Kogler")
  end

  describe ".add_class_helper_methods_to(klass)" do

    it "adds the method 'xapian_id' to the configured class" do
      @object.should respond_to(:xapian_id)
    end

    it "adds the method 'order_condition' to the configured class" do
      @object.class.should respond_to(:order_condition)
    end

    it "adds an after save hook to the configured class" do
      DatamapperObject.hooks[:after_save].should be_a_kind_of(Proc)
    end

    it "adds an after destroy hook to the configured class" do
      DatamapperObject.hooks[:after_destroy].should be_a_kind_of(Proc)
    end

    it "adds a class method to reindex all objects of a class" do
      DatamapperObject.should respond_to(:rebuild_xapian_index)
    end

    it "adds the helper methods from the base class" do
      DatamapperObject.should respond_to(:search)
    end

  end

  describe ".add_doc_helper_methods_to(obj)" do

    it "adds the method 'id' to the object" do
      mod = Module.new
      XapianDb::Adapters::DatamapperAdapter.add_doc_helper_methods_to(mod)
      mod.instance_methods.should include(:id)
    end

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

  describe ".primary_key_for(klass)" do

    it "returns the name of the primary key column" do
      XapianDb::Adapters::DatamapperAdapter.primary_key_for(DatamapperObject).should == DatamapperObject.serial.name
    end

  end

  describe "the after save hook" do
    it "should (re)index the object" do
      @object.save
      XapianDb.search("Kogler").size.should == 1
    end

    it "should not index the object if an ignore expression in the blueprint is met" do
      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.index :name
        blueprint.ignore_if {name == "Kogler"}
      end
      @object.save
      XapianDb.search("Kogler").size.should == 0
    end

    it "should index the object if an ignore expression in the blueprint is not met" do
      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.index :name
        blueprint.ignore_if {name == "not Kogler"}
      end
      @object.save
      XapianDb.search("Kogler").size.should == 1
    end

  end

  describe "the after destroy hook" do
    it "should remove the object from the index" do
      @object.save
      XapianDb.search("Kogler").size.should == 1
      @object.destroy
      XapianDb.search("Kogler").size.should == 0
    end
  end

  describe ".id" do

    it "should return the id of the object that is linked with the document" do
      @object.save
      doc = XapianDb.search("Kogler").first
      doc.id.should == @object.id
    end
  end

  describe ".indexed_object" do

    it "should return the object that is linked with the document" do
      @object.save
      doc = XapianDb.search("Kogler").first
      doc.indexed_object.should be_equal(@object)
    end
  end

  describe ".rebuild_xapian_index" do
    it "should (re)index all objects of this class" do
      @object.save
      XapianDb.search("Kogler").size.should == 1

      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      XapianDb.search("Kogler").size.should == 0

      DatamapperObject.rebuild_xapian_index
      XapianDb.search("Kogler").size.should == 1
    end

    it "should respect an ignore expression" do
      @object.save
      XapianDb.search("Kogler").size.should == 1

      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      XapianDb.search("Kogler").size.should == 0

      XapianDb::DocumentBlueprint.setup(:DatamapperObject) do |blueprint|
        blueprint.index :name
        blueprint.ignore_if {name == "Kogler"}
      end

      DatamapperObject.rebuild_xapian_index
      XapianDb.search("Kogler").size.should == 0
    end

  end

end

# encoding: utf-8

# Theses specs describe and test the helper methods that are added to indexed classes
# by the active_record adapter
# @author Gernot Kogler

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/xapian_db/adapters/active_record_adapter.rb')

describe XapianDb::Adapters::ActiveRecordAdapter do

  before :each do
    XapianDb.setup do |config|
      config.database :memory
      config.adapter :active_record
      config.writer  :direct
    end

    XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
      blueprint.index :name
    end
  end

  let(:object) { ActiveRecordObject.new(1, "Kogler") }

  describe ".add_class_helper_methods_to(klass)" do

    it "should raise an exception if no database is configured for the adapter" do
    end

    it "adds the method 'xapian_id' to the configured class" do
      expect(object).to respond_to(:xapian_id)
    end

    it "adds the method 'order_condition' to the configured class" do
      expect(object.class).to respond_to(:order_condition)
    end

    it "adds an after save hook to the configured class" do
      expect(ActiveRecordObject.hooks[:after_save].length).to eq(1)
      ActiveRecordObject.hooks[:after_save].each do |hook|
        expect(hook).to be_a_kind_of(Proc)
      end
    end

    it "does not add an after save hook if autoindexing is turned off for this blueprint" do
      ActiveRecordObject.reset
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.autoindex false
      end
      expect(ActiveRecordObject.hooks[:after_save]).to be_empty
    end

    it "adds an after destroy hook to the configured class" do
      # expect 2 because the ActiveRecordObject implementation for these specs adds an :after_destroy on :after_commit, too
      expect(ActiveRecordObject.hooks[:after_destroy].length).to eq(2)
      ActiveRecordObject.hooks[:after_destroy].each do |hook|
        expect(hook).to be_a_kind_of(Proc)
      end
    end

    it "adds a class method to reindex all objects of a class" do
      expect(ActiveRecordObject).to respond_to(:rebuild_xapian_index)
    end

    it "adds the helper methods from the base class" do
      expect(ActiveRecordObject).to respond_to(:search)
    end
  end

  describe ".add_doc_helper_methods_to(obj)" do

    it "adds the method 'id' to the object" do
      mod = Module.new
      XapianDb::Adapters::ActiveRecordAdapter.add_doc_helper_methods_to(mod)
      expect(mod.instance_methods).to include(:id)
    end

    it "adds the method 'indexed_object' to the object" do
      mod = Module.new
      XapianDb::Adapters::ActiveRecordAdapter.add_doc_helper_methods_to(mod)
      expect(mod.instance_methods).to include(:indexed_object)
    end
  end

  describe ".xapian_id" do
    it "returns a unique id composed of the class name and the id" do
      expect(object.xapian_id).to eq("#{object.class}-#{object.id}")
    end
  end

  describe ".primary_key_for(klass)" do

    it "returns the name of the primary key column" do
      expect(XapianDb::Adapters::ActiveRecordAdapter.primary_key_for(ActiveRecordObject)).to eq(ActiveRecordObject.primary_key)
    end

  end

  describe "the after commit hook" do

    it "should not (re)index the object, if it is a destroy transaction" do
      expect(XapianDb).not_to receive(:reindex)
      object.destroy
    end

    it "should (re)index the object, if it is a create/update action" do
      expect(XapianDb).to receive(:reindex)
      object.save
    end

    it "should not index the object if an ignore expression in the blueprint is met" do
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name
        blueprint.ignore_if {name == "Kogler"}
      end
      object.save
      expect(XapianDb.search("Kogler").size).to eq(0)
    end

    it "should index the object if an ignore expression in the blueprint is not met" do
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name
        blueprint.ignore_if {name == "not Kogler"}
      end
      object.save
      expect(XapianDb.search("Kogler").size).to eq(1)
    end

    it "should (re)index a dependent object if necessary" do
      class IndexedActiveRecordObject < ActiveRecordObject; end; IndexedActiveRecordObject.reset
      class ChangingActiveRecordObject < ActiveRecordObject; end; ChangingActiveRecordObject.reset
      object_that_should_update = IndexedActiveRecordObject.new 1, 'Müller'
      object_that_changes       = ChangingActiveRecordObject.new 1, 'Meier'

      XapianDb::DocumentBlueprint.setup(:IndexedActiveRecordObject) do |blueprint|
        blueprint.index :name

        blueprint.dependency :ChangingActiveRecordObject, when_changed: %i(name) do |_object|
          [object_that_should_update]
        end
      end
      previous_changes = { 'name' => 'something' }
      allow(object_that_changes).to receive(:previous_changes).and_return(previous_changes)

      expect(XapianDb).to receive(:reindex).with(object_that_should_update, true, changed_attrs: previous_changes.keys)
      expect(XapianDb).not_to receive(:reindex).with(object_that_changes, true, changed_attrs: previous_changes.keys)

      object_that_changes.save
    end
  end

  describe "the after destroy hook" do
    it "should remove the object from the index" do
      object.save
      expect(XapianDb.search("Kogler").size).to eq(1)
      object.destroy
      expect(XapianDb.search("Kogler").size).to eq(0)
    end
  end

  describe ".id" do

    it "should return the id of the object that is linked with the document" do
      object.save
      doc = XapianDb.search("Kogler").first
      expect(doc.id).to eq(object.id)
    end
  end

  describe ".indexed_object" do

    it "should return the object that is linked with the document" do
      object.save
      doc = XapianDb.search("Kogler").first
      # Since we do not have identity map in active_record, we can only
      # compare the ids, not the objects
      expect(doc.indexed_object.id).to eq(object.id)
    end
  end

  describe ".rebuild_xapian_index" do
    it "should (re)index all objects of this class" do
      object.save
      expect(XapianDb.search("Kogler").size).to eq(1)

      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      expect(XapianDb.search("Kogler").size).to eq(0)

      ActiveRecordObject.rebuild_xapian_index
      expect(XapianDb.search("Kogler").size).to eq(1)
    end

    it "should respect an ignore expression" do
      object.save
      expect(XapianDb.search("Kogler").size).to eq(1)

      # We reopen the in memory database to destroy the index
      XapianDb.setup do |config|
        config.database :memory
      end
      expect(XapianDb.search("Kogler").size).to eq(0)

      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.index :name
        blueprint.ignore_if {name == "Kogler"}
      end

      ActiveRecordObject.rebuild_xapian_index
      expect(XapianDb.search("Kogler").size).to eq(0)
    end

  end

end

# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::BeanstalkWorker do

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
    @obj = ActiveRecordObject.new(1, "Kogler")
  end

  describe ".index_task(options)" do
    it "adds an object to the index" do
      @obj.save
      XapianDb.database.delete_docs_of_class @obj.class
      expect(XapianDb.database.size).to eq(0)
      XapianDb::IndexWriters::BeanstalkWorker.new.index_task :class => @obj.class.name, :id => @obj.id
      expect(XapianDb.database.size).to eq(1)
    end
  end

  describe ".delete_doc_task(options)" do
    it "removes an object from the index" do
      @obj.save
      expect(XapianDb.database.size).to eq(1)
      XapianDb::IndexWriters::BeanstalkWorker.new.delete_doc_task :xapian_id => @obj.xapian_id
      expect(XapianDb.database.size).to eq(0)
    end
  end

  describe ".reindex_class_task(options)" do

    it "adds all instances of a class to the index" do
      @obj.save
      XapianDb.database.delete_docs_of_class @obj.class
      expect(XapianDb.database.size).to eq(0)
      XapianDb::IndexWriters::BeanstalkWorker.new.reindex_class_task :class => @obj.class.name
      expect(XapianDb.database.size).to eq(1)
    end

  end

end
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/xapian_db/index_writers/beanstalk_writer')

describe XapianDb::IndexWriters::BeanstalkWriter do

  class BeanstalkDummy
    def put(args)
    end
  end

  let (:object) { ActiveRecordObject.new 1, "Gernot" }

  before :each do
    allow(described_class).to receive(:beanstalk).and_return(BeanstalkDummy.new)
  end

  describe ".index(obj, commit=true, changed_attrs: [])" do
    it "puts the index task on the beanstalk queue" do
      changed_attrs = ['name']
      expect(described_class.beanstalk).to receive(:put).with({task: "index_task", class: object.class.name, id: object.id, changed_attrs: changed_attrs }.to_json)
      XapianDb::IndexWriters::BeanstalkWriter.index object, true, changed_attrs: changed_attrs
    end
  end

  describe ".delete_doc_with(xapian_id)" do
    it "puts the delete task on the beanstalk queue" do
      expect(described_class.beanstalk).to receive(:put).with({ :task => "delete_doc_task", :xapian_id => object.xapian_id }.to_json)
      XapianDb::IndexWriters::BeanstalkWriter.delete_doc_with object.xapian_id
    end
  end

  describe ".reindex(klass)" do
    it "puts the reindex task on the resque queue" do
      expect(described_class.beanstalk).to receive(:put).with({ :task => "reindex_class_task", :class => object.class.name }.to_json)
      XapianDb::IndexWriters::BeanstalkWriter.reindex_class ActiveRecordObject
    end
  end
end

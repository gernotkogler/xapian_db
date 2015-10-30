# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/xapian_db/index_writers/resque_writer')

describe XapianDb::IndexWriters::ResqueWriter do

  class TestIndexClass
    def id
      28
    end
  end

  class DummyWorker
  end

  before :each do
    allow(described_class).to receive(:worker_class) { DummyWorker }
  end

  describe ".index" do
    let(:object) { TestIndexClass.new }

    it "puts the index task on the resque queue" do
      changed_attrs = ['name']
      expect(Resque).to receive(:enqueue).with(DummyWorker, :index, class: 'TestIndexClass', id: 28, changed_attrs: changed_attrs )
      described_class.index object, true, changed_attrs: changed_attrs
    end
  end

  describe ".delete_doc_with" do
    it "puts the delete task on the resque queue" do
      expect(Resque).to receive(:enqueue).with(DummyWorker, :delete_doc, :xapian_id => 91)
      described_class.delete_doc_with 91
    end
  end

  describe ".reindex_class" do
    it "puts the reindex task on the resque queue" do
      expect(Resque).to receive(:enqueue).with(DummyWorker, :reindex_class, :class => 'TestIndexClass')
      described_class.reindex_class TestIndexClass
    end
  end

end

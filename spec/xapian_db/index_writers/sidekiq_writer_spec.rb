# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/xapian_db/index_writers/sidekiq_writer')

describe XapianDb::IndexWriters::SidekiqWriter do

  class TestIndexClass
    def id
      28
    end
  end

  class DummyWorker
  end

  before :each do
    described_class.stub(:worker_class) { DummyWorker }
  end

  describe ".index" do
    let(:object) { TestIndexClass.new }

    it "puts the index task on the sidekiq queue" do
      Sidekiq::Client.should_receive(:enqueue).with(DummyWorker, :index, :class => 'TestIndexClass', :id => 28)
      described_class.index object
    end
  end

  describe ".delete_doc_with" do
    it "puts the delete task on the sidekiq queue" do
      Sidekiq::Client.should_receive(:enqueue).with(DummyWorker, :delete_doc, :xapian_id => 91)
      described_class.delete_doc_with 91
    end
  end

  describe ".reindex_class" do
    it "puts the reindex task on the sidekiq queue" do
      Sidekiq::Client.should_receive(:enqueue).with(DummyWorker, :reindex_class, :class => 'TestIndexClass')
      described_class.reindex_class TestIndexClass
    end
  end

end

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
    allow(described_class).to receive(:worker_class) { DummyWorker }
  end

  describe ".index" do
    let(:object) { TestIndexClass.new }
    let(:changed_attrs) { ['name'] }
    let(:expected_arguments) {
      {
        'queue' => 'xapian_db',
        'class' => DummyWorker,
        'args' => ['index', { class: 'TestIndexClass', id: 28, changed_attrs: }.to_json],
        'retry' => false
      }
    }

    it "puts the index task on the sidekiq queue" do
      expect(Sidekiq::Client).to receive(:push).with(expected_arguments)
      described_class.index(object, true, changed_attrs:)
    end
  end

  describe ".delete_doc_with" do
    let(:expected_arguments) {
      {
        'queue' => 'xapian_db',
        'class' => DummyWorker,
        'args' => ['delete_doc', { xapian_id: 91 }.to_json],
        'retry' => false
      }
    }

    it "puts the delete task on the sidekiq queue" do
      expect(Sidekiq::Client).to receive(:push).with(expected_arguments)
      described_class.delete_doc_with 91
    end
  end

  describe ".reindex_class" do
    let(:expected_arguments) {
      {
        'queue' => 'xapian_db',
        'class' => DummyWorker,
        'args' => ['reindex_class', { class: 'TestIndexClass' }.to_json],
        'retry' => false
      }
    }
    it "puts the reindex task on the sidekiq queue" do
      expect(Sidekiq::Client).to receive(:push).with(expected_arguments)
      described_class.reindex_class TestIndexClass
    end
  end
end

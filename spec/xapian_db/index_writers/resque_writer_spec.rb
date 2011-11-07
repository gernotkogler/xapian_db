require 'xapian_db'

describe XapianDb::IndexWriters::ResqueWriter do

  class TestIndexClass
    def id
      28
    end
  end

  class DummyWorker
  end

  subject { XapianDb::IndexWriters::ResqueWriter }

  before :each do
    subject.stub(:worker_class) { DummyWorker }
  end

  describe ".index" do
    let(:object) { TestIndexClass.new }

    it "puts the index task on the resque queue" do
      Resque.should_receive(:enqueue).with(DummyWorker, :index, :class => 'TestIndexClass', :id => 28)
      subject.index object
    end
  end

  describe ".delete_doc_with" do
    it "puts the delete task on the resque queue" do
      Resque.should_receive(:enqueue).with(DummyWorker, :delete_doc, :xapian_id => 91)
      subject.delete_doc_with 91
    end
  end

  describe ".reindex_class" do
    it "puts the reindex task on the resque queue" do
      Resque.should_receive(:enqueue).with(DummyWorker, :reindex_class, :class => 'TestIndexClass')
      subject.reindex_class TestIndexClass
    end
  end

end

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::SidekiqWorker do

  subject { XapianDb::IndexWriters::SidekiqWorker }

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
  end
  let(:obj) { ActiveRecordObject.new(1, "Kogler") }

  describe ".queue" do
    it "returns the queue name specified in the config" do
      allow(XapianDb::Config).to receive(:sidekiq_queue) { 'my_queue' }
      expect(subject.queue).to eq('my_queue')
    end
  end

  describe ".index" do
    it "adds an object to the index" do
      obj.save
      XapianDb.database.delete_docs_of_class obj.class
      expect(XapianDb.database.size).to eq(0)
      subject.perform 'index', 'class' => obj.class.name, 'id' => obj.id
      expect(XapianDb.database.size).to eq(1)
    end
  end

  describe ".delete_doc" do
    it "removes an object from the index" do
      obj.save
      expect(XapianDb.database.size).to eq(1)
      subject.perform 'delete_doc', 'xapian_id' => obj.xapian_id
      expect(XapianDb.database.size).to eq(0)
    end
  end

  describe ".reindex_class" do
    it "adds all instances of a class to the index" do
      obj.save
      XapianDb.database.delete_docs_of_class obj.class
      expect(XapianDb.database.size).to eq(0)
      subject.perform 'reindex_class', 'class' => obj.class.name
      expect(XapianDb.database.size).to eq(1)
    end
  end

end

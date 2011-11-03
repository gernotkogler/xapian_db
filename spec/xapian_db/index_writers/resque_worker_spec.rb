require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::IndexWriters::ResqueWorker do

  subject { XapianDb::IndexWriters::ResqueWorker }

  before :each do
    XapianDb.setup do |config|
      config.adapter  :active_record
      config.database :memory
      config.writer   :direct
    end
    XapianDb::DocumentBlueprint.setup(ActiveRecordObject) do |blueprint|
      blueprint.attribute :id
      blueprint.attribute :name
    end
  end
  let(:obj) { ActiveRecordObject.new(1, "Kogler") }

  describe ".queue" do
    it "returns the queue name specified in the config" do
      XapianDb::Config.stub(:resque_queue) { 'my_queue' }
      subject.queue.should == 'my_queue'
    end
  end

  describe ".index" do
    it "adds an object to the index" do
      obj.save
      XapianDb.database.delete_docs_of_class obj.class
      XapianDb.database.size.should == 0
      subject.perform 'index', 'class' => obj.class.name, 'id' => obj.id
      XapianDb.database.size.should == 1
    end
  end

  describe ".delete_doc" do
    it "removes an object from the index" do
      obj.save
      XapianDb.database.size.should == 1
      subject.perform 'delete_doc', 'xapian_id' => obj.xapian_id
      XapianDb.database.size.should == 0
    end
  end

  describe ".reindex_class" do
    it "adds all instances of a class to the index" do
      obj.save
      XapianDb.database.delete_docs_of_class obj.class
      XapianDb.database.size.should == 0
      subject.perform 'reindex_class', 'class' => obj.class.name
      XapianDb.database.size.should == 1
    end
  end

end

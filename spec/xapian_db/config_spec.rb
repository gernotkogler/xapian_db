# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Config do

  describe ".setup(&block)" do

    describe ".database" do
      it "accepts a in memory database" do
        XapianDb::Config.setup do |config|
          config.database :memory
        end
        XapianDb.database.should be_a_kind_of XapianDb::InMemoryDatabase
      end

      it "accepts a persistent database" do
        db_path = "/tmp/xapian_db"
        XapianDb::Config.setup do |config|
          config.database db_path
        end
        File.exist?(db_path).should be_true
        XapianDb.database.should be_a_kind_of XapianDb::PersistentDatabase
        FileUtils.rm_rf db_path
      end

      it "reopens the database if it already exists" do
        db_path = "/tmp/xapian_db"
        FileUtils.rm_rf db_path

        XapianDb::Config.setup do |config|
          config.database db_path
        end

        # Put a doc into the database
        doc = Xapian::Document.new
        XapianDb.database.store_doc(doc).should be_true

        # Now reopen the database
        XapianDb::Config.setup do |config|
          config.database db_path
        end
        XapianDb.database.size.should == 1 # The doc should still be there
      end

    end

    describe ".adapter" do
      it "accepts a generic adapter" do
        XapianDb::Config.setup do |config|
          config.adapter :generic
        end
        XapianDb::Config.adapter.should be_equal XapianDb::Adapters::GenericAdapter
      end

      it "accepts a datamapper adapter" do
        XapianDb::Config.setup do |config|
          config.adapter :datamapper
        end
        XapianDb::Config.adapter.should be_equal XapianDb::Adapters::DatamapperAdapter
      end

      it "accepts an active_record adapter" do
        XapianDb::Config.setup do |config|
          config.adapter :active_record
        end
        XapianDb::Config.adapter.should be_equal XapianDb::Adapters::ActiveRecordAdapter
      end

      it "raises an error if the configured adapter is unknown" do
        lambda{XapianDb::Config.setup do |config|
          config.adapter :unknown
        end}.should raise_error
      end
    end

    describe ".writer" do
      it "accepts a direct writer" do
        XapianDb::Config.setup do |config|
          config.writer :direct
        end
        XapianDb::Config.writer.should be_equal XapianDb::IndexWriters::DirectWriter
      end

      it "accepts the beanstalk writer, if the beanstalk-client gem is installed" do
        if defined? XapianDb::IndexWriters::BeanstalkWriter
          XapianDb::Config.setup do |config|
            config.writer :beanstalk
          end
          XapianDb::Config.writer.should be_equal XapianDb::IndexWriters::BeanstalkWriter
        else
          pending "cannot run this spec without the beanstalk-client gem installed"
        end
      end

      it "raises an error if the configured writer is unknown" do
        lambda{XapianDb::Config.setup do |config|
          config.writer :unknown
        end}.should raise_error
      end

    end

    describe ".beanstalk_daemon" do
      it "defaults to localhost:11300" do
        XapianDb::Config.beanstalk_daemon_url.should == "localhost:11300"
      end

      it "accepts an url" do
        XapianDb::Config.setup do |config|
          config.beanstalk_daemon_url "localhost:9000"
        end
        XapianDb::Config.beanstalk_daemon_url.should == "localhost:9000"
      end

    end

    describe ".language" do

      it "creates a stemmer and a stopper for a supported language" do
        XapianDb::Config.setup do |config|
          config.language :de
        end
        XapianDb::Config.stemmer.should be_a_kind_of Xapian::Stem
        XapianDb::Config.stopper.should be_a_kind_of Xapian::SimpleStopper
      end

      it "does not create a stopper for the argument :none" do
        XapianDb::Config.setup do |config|
          config.language :none
        end
        XapianDb::Config.stemmer.should be_a_kind_of Xapian::Stem
        XapianDb::Config.stopper.should_not be
      end

      it "raises an invalid argument error if an unsupported language is applied" do
        lambda{XapianDb::Config.setup do |config|
          config.language :not_supported
        end}.should raise_error ArgumentError
      end

      it "can handle nil as an argument" do
        XapianDb::Config.setup do |config|
          config.language nil
        end
        XapianDb::Config.stemmer.should be_a_kind_of Xapian::Stem
        XapianDb::Config.stopper.should_not be
      end

    end
  end

end
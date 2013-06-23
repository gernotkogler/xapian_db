# -*- coding: utf-8 -*-
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

        XapianDb.should_receive :create_db
        XapianDb::Config.setup do |config|
          config.database db_path
        end

        XapianDb.should_receive :open_db
        XapianDb::Config.setup do |config|
          config.database db_path
        end
      end

      it "handles the existence of an empty index directory gracefully" do
        db_path = "/tmp/xapian_db"
        FileUtils.rm_rf db_path
        FileUtils.mkdir_p db_path
        XapianDb::Config.setup do |config|
          config.database db_path
        end
        XapianDb.database.size
        FileUtils.rm_rf db_path
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

      it "accepts the resque writer, if the resque gem is installed" do
        if defined? XapianDb::IndexWriters::ResqueWriter
          XapianDb::Config.setup do |config|
            config.writer :resque
          end
          XapianDb::Config.writer.should == XapianDb::IndexWriters::ResqueWriter
        else
          pending "cannot run this spec without the resque gem installed"
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

    describe ".resque_queue" do
      it "returns 'xapian_db' by default" do
        XapianDb::Config.resque_queue.should == 'xapian_db'
      end

      it "accepts a name" do
        XapianDb::Config.setup do |config|
          config.resque_queue 'my_queue'
        end
        XapianDb::Config.resque_queue.should == 'my_queue'
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

    describe ".term_min_length" do
      it "accepts a number for the min length of the indexed terms" do
        XapianDb::Config.setup do |config|
          config.term_min_length 2
        end
        XapianDb::Config.term_min_length.should == 2
      end
    end

    describe ".term_splitter_count" do
      it "accepts a number for the term splitter size" do
        XapianDb::Config.setup do |config|
          config.term_splitter_count 3
        end
        XapianDb::Config.term_splitter_count.should == 3
      end

      it "defaults to 0" do
        XapianDb::Config.term_splitter_count.should == 0
      end
    end

    describe ".enable_query_flag <QUERY_FLAG>" do
      it "adds the query flag to the enabled flags collection" do
        XapianDb::Config.setup do |config|
          config.enable_query_flag Xapian::QueryParser::FLAG_PHRASE
        end
        XapianDb::Config.query_flags.should include(Xapian::QueryParser::FLAG_PHRASE)
      end
    end

    describe ".disable_query_flag <QUERY_FLAG>" do
      it "removes the query flag from the enabled flags collection" do
        XapianDb::Config.instance_variable_set :@_enabled_query_flags, [Xapian::QueryParser::FLAG_WILDCARD]
        XapianDb::Config.setup do |config|
          config.disable_query_flag Xapian::QueryParser::FLAG_WILDCARD
        end
        XapianDb::Config.query_flags.should_not include(Xapian::QueryParser::FLAG_WILDCARD)
      end
    end

  end
end

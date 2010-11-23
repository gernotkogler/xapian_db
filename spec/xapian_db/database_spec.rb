# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb do
  
  describe ".create_db" do
    
    it "should create an in memory database by default" do
      db = XapianDb.create_db
      db.reader.should be_a_kind_of(Xapian::Database)
      db.writer.should be_a_kind_of(Xapian::Database)
    end

    it "should create a database on disk if a path is given" do
      temp_dir = "/tmp/xapiandb"
      db = XapianDb.create_db(:path => temp_dir)
      db.reader.should be_a_kind_of(Xapian::Database)
      db.writer.should be_a_kind_of(Xapian::Database)
      File.exists?(temp_dir).should be_true
      FileUtils.rm_rf temp_dir
    end
    
  end
  
end

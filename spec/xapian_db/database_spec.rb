# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Database do
  
  describe ".create" do
    
    it "should create an in memory database by default" do
      db = XapianDb::Database.create
      db.reader.should be_a_kind_of(Xapian::Database)
      db.writer.should be_a_kind_of(Xapian::Database)
    end
    
  end
  
end

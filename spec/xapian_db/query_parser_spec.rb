# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::QueryParser do
  
  before :all do
    @db = XapianDb.create_db
  end
  
  describe ".parse" do
    
    it "returns a Xapian::Query object" do
      XapianDb::QueryParser.new(@db).parse("foo").should be_a_kind_of(Xapian::Query)
    end
    
  end
  
end
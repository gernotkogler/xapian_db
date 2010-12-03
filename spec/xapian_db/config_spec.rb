# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Config do

  describe ".setup(&block)" do
    
    it "accepts a database" do
      db = XapianDb::Database.new
      XapianDb::Config.setup do |config|
        config.database = db
      end
      XapianDb::Config.database.should be_equal(db)
    end
    
  end
  
end
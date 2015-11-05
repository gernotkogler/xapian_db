# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::QueryParser do

  before :all do
    @db = XapianDb.create_db
  end

  describe ".parse" do

    it "returns nil if the search expression is nil" do
      expect(XapianDb::QueryParser.new(@db).parse(nil)).not_to be
    end

    it "returns nil if the search expression is an empty string" do
      expect(XapianDb::QueryParser.new(@db).parse(" ")).not_to be
    end

    it "returns a Xapian::Query object" do
      expect(XapianDb::QueryParser.new(@db).parse("foo")).to be_a_kind_of(Xapian::Query)
    end

    it "responds to spelling_suggestion" do
      expect(XapianDb::QueryParser.new(@db)).to respond_to(:spelling_suggestion)
    end

  end

end
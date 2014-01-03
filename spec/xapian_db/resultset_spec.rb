# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Resultset do

  before :each do

    # Setup a blueprint
    XapianDb::DocumentBlueprint.setup(:IndexedObject) do |blueprint|
      blueprint.attribute :name
    end

    @name = "Gernot"

    # Mock a Xapian search result (Xapian::Enquire)
    @enquiry = mock(Xapian::Enquire)
    @mset    = mock(Xapian::MSet)

    # Create 3 matches and docs to play with
    @matches = []
    3.times do |i|
      match   = mock(Xapian::Match)
      doc     = Xapian::Document.new
      doc.add_value(0, IndexedObject.name)
      doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:name), "#{@name}#{i}")
      match.stub!(:document).and_return(doc)
      match.stub!(:percent).and_return(90)
      @matches << match
    end
    @mset.stub!(:matches_estimated).and_return(@matches.size)
    @mset.stub!(:matches).and_return(@matches)
    @enquiry.stub!(:mset).and_return(@mset)

  end

  it "behaves like an array" do
    resultset = XapianDb::Resultset.new(nil, {})
    %w(size [] each).each do |method|
      resultset.should respond_to(method)
    end
  end

  it "is compatible with kaminari pagination" do
    resultset = XapianDb::Resultset.new(nil, {})
    %w(total_count num_pages limit_value current_page).each do |method|
      resultset.should respond_to(method)
    end
  end

  it "is compatible with will_paginate pagination" do
    resultset = XapianDb::Resultset.new(nil, {})
    resultset.should respond_to(:total_entries)
  end

  describe ".initialize(enquiry, options)" do

    it "creates a valid, empty result set if we pass nil for the enquiry" do
      resultset = XapianDb::Resultset.new(nil, {})
      resultset.hits.should          == 0
      resultset.size.should          == 0
      resultset.current_page.should  == 0
      resultset.total_pages.should   == 0
      resultset.limit_value.should   == 0
    end

    it "raises an exception if an unsupported option is passed" do
      lambda{XapianDb::Resultset.new(@enquiry, :unsupported => "?")}.should raise_error
    end

    it "accepts a limit option (as a string or an integer)" do
      @mset.stub!(:matches).and_return(@matches[0..1])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :limit => "2")
      resultset.hits.should          == 3
      resultset.size.should          == 2
      resultset.current_page.should  == 1
      resultset.total_pages.should   == 2
      resultset.total_count.should   == @matches.size
      resultset.total_entries.should == @matches.size
    end

    it "accepts a per_page option (as a string or an integer)" do
      @mset.stub!(:matches).and_return(@matches[0..1])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => "2")

      resultset.hits.should         == 3
      resultset.size.should         == 2
      resultset.current_page.should == 1
      resultset.total_pages.should  == 2
    end

    it "accepts a page number (as a string or an integer)" do
      @mset.stub!(:matches).and_return(@matches[2..2])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => "2", :page => "2")

      resultset.hits.should         == 3
      resultset.size.should         == 1
      resultset.current_page.should == 2
      resultset.total_pages.should  == 2
    end

    it "accepts nil as a page number" do
      @mset.stub!(:matches).and_return(@matches[0..1])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => nil)

      resultset.hits.should         == 3
      resultset.size.should         == 2
      resultset.current_page.should == 1
      resultset.total_pages.should  == 2
    end

    it "raises an exception if page is requested that does not exist" do
      lambda{XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 3)}.should raise_error
    end

    it "should populate itself with found xapian documents" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      resultset.first.should be_a_kind_of(Xapian::Document)
    end

    it "should decorate the Xapian documents with attribute accessors" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      doc = resultset.first
      doc.respond_to?(:name).should be_true
      doc.name.should == "#{@name}0"
    end

    it "should add the score of a match to the document" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      doc = resultset.first
      doc.score.should == 90
    end

    it "can handle a page option as a string" do
      @mset.stub!(:matches).and_return(@matches[2..2])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => "2")

      resultset.hits.should         == 3
      resultset.size.should         == 1
      resultset.current_page.should == 2
      resultset.total_pages.should  == 2
    end

  end

  describe ".previous_page" do

    it "should return nil if we are at page 1" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 1)
      resultset.previous_page.should_not be
    end

    it "should return 1 if we are at page 2" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      resultset.previous_page.should == 1
    end

  end

  describe ".next_page" do

    it "should return 2 if we are at page 1" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 1)
      resultset.next_page.should == 2
    end

    it "should return nil if we are on the last page" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      resultset.next_page.should_not be
    end
  end

end

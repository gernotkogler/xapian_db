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
    @enquiry = double(Xapian::Enquire)
    @mset    = double(Xapian::MSet)

    # Create 3 matches and docs to play with
    @matches = []
    3.times do |i|
      match   = double(Xapian::Match)
      doc     = Xapian::Document.new
      doc.add_value(0, IndexedObject.name)
      doc.add_value(XapianDb::DocumentBlueprint.value_number_for(:name), "#{@name}#{i}")
      allow(match).to receive(:document).and_return(doc)
      allow(match).to receive(:percent).and_return(90)
      @matches << match
    end
    allow(@mset).to receive(:matches_estimated).and_return(@matches.size)
    allow(@mset).to receive(:matches).and_return(@matches)
    allow(@enquiry).to receive(:mset).and_return(@mset)

  end

  it "behaves like an array" do
    resultset = XapianDb::Resultset.new(nil, {})
    %w(size [] each).each do |method|
      expect(resultset).to respond_to(method)
    end
  end

  it "is compatible with kaminari pagination" do
    resultset = XapianDb::Resultset.new(nil, {})
    %w(total_count num_pages limit_value current_page).each do |method|
      expect(resultset).to respond_to(method)
    end
  end

  it "is compatible with will_paginate pagination" do
    resultset = XapianDb::Resultset.new(nil, {})
    expect(resultset).to respond_to(:total_entries)
  end

  describe ".initialize(enquiry, options)" do

    it "creates a valid, empty result set if we pass nil for the enquiry" do
      resultset = XapianDb::Resultset.new(nil, {})
      expect(resultset.hits).to          eq(0)
      expect(resultset.size).to          eq(0)
      expect(resultset.current_page).to  eq(0)
      expect(resultset.total_pages).to   eq(0)
      expect(resultset.limit_value).to   eq(0)
    end

    it "raises an exception if an unsupported option is passed" do
      expect{XapianDb::Resultset.new(@enquiry, :unsupported => "?")}.to raise_error
    end

    it "accepts a limit option (as a string or an integer)" do
      allow(@mset).to receive(:matches).and_return(@matches[0..1])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :limit => "2")
      expect(resultset.hits).to          eq(3)
      expect(resultset.size).to          eq(2)
      expect(resultset.current_page).to  eq(1)
      expect(resultset.total_pages).to   eq(2)
      expect(resultset.total_count).to   eq(@matches.size)
      expect(resultset.total_entries).to eq(@matches.size)
    end

    it "accepts a per_page option (as a string or an integer)" do
      allow(@mset).to receive(:matches).and_return(@matches[0..1])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => "2")

      expect(resultset.hits).to         eq(3)
      expect(resultset.size).to         eq(2)
      expect(resultset.current_page).to eq(1)
      expect(resultset.total_pages).to  eq(2)
    end

    it "accepts a page number (as a string or an integer)" do
      allow(@mset).to receive(:matches).and_return(@matches[2..2])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => "2", :page => "2")

      expect(resultset.hits).to         eq(3)
      expect(resultset.size).to         eq(1)
      expect(resultset.current_page).to eq(2)
      expect(resultset.total_pages).to  eq(2)
    end

    it "accepts nil as a page number" do
      allow(@mset).to receive(:matches).and_return(@matches[0..1])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => nil)

      expect(resultset.hits).to         eq(3)
      expect(resultset.size).to         eq(2)
      expect(resultset.current_page).to eq(1)
      expect(resultset.total_pages).to  eq(2)
    end

    it "raises an exception if page is requested that does not exist" do
      expect{XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 3)}.to raise_error
    end

    it "should populate itself with found xapian documents" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      expect(resultset.first).to be_a_kind_of(Xapian::Document)
    end

    it "should decorate the Xapian documents with attribute accessors" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      doc = resultset.first
      expect(doc.respond_to?(:name)).to be_truthy
      expect(doc.name).to eq("#{@name}0")
    end

    it "should add the score of a match to the document" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      doc = resultset.first
      expect(doc.score).to eq(90)
    end

    it "can handle a page option as a string" do
      allow(@mset).to receive(:matches).and_return(@matches[2..2])
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => "2")

      expect(resultset.hits).to         eq(3)
      expect(resultset.size).to         eq(1)
      expect(resultset.current_page).to eq(2)
      expect(resultset.total_pages).to  eq(2)
    end

  end

  describe ".previous_page" do

    it "should return nil if we are at page 1" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 1)
      expect(resultset.previous_page).not_to be
    end

    it "should return 1 if we are at page 2" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      expect(resultset.previous_page).to eq(1)
    end

  end

  describe ".next_page" do

    it "should return 2 if we are at page 1" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 1)
      expect(resultset.next_page).to eq(2)
    end

    it "should return nil if we are on the last page" do
      resultset = XapianDb::Resultset.new(@enquiry, :db_size => @matches.size, :per_page => 2, :page => 2)
      expect(resultset.next_page).not_to be
    end
  end

end

# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Resultset do

  before :each do

    @name = "Gernot"

    # Mock a Xapian search result (Xapian::Enquire)
    enquiry = mock(Xapian::Enquire)
    mset    = mock(Xapian::MSet)
    match   = mock(Xapian::Match)
    doc     = Xapian::Document.new

    match.stub!(:document).and_return(doc)
    mset.stub!(:matches_estimated).and_return(1)
    mset.stub!(:matches).and_return([match])
    enquiry.stub!(:mset).and_return(mset)

    doc.add_value(0, IndexedObject.name)
    doc.add_value(1, @name)

    # Setup a blueprint
    XapianDb::DocumentBlueprint.setup(IndexedObject) do |blueprint|
      blueprint.attribute :name
    end

    @result = XapianDb::Resultset.new(enquiry, :per_page => 10)
  end

  describe ".initialize(enquiry, options)" do

    it "creates a valid, empty result set if we pass nil for the enquiry" do
      resultset = XapianDb::Resultset.new(nil, {})
      resultset.size.should == 0
      resultset.current_page.should == 1
      resultset.total_pages.should == 0
    end

  end

  describe ".paginate(opts={})" do

    it "should return an array of Xapian documents if the page parameters are within the resultset size" do
      @result.paginate(:page => 1).should be_a_kind_of(Array)
      @result.paginate(:page => 1).size.should == 1
      @result.paginate(:page => 1).first.should be_a_kind_of(Xapian::Document)
    end

    it "should decorate the returned Xapian documents with attribute accessors" do
      doc = @result.paginate(:page => 1).first
      doc.respond_to?(:name).should be_true
      doc.name.should == @name
    end

    it "accepts nil for the page number" do
      @result.paginate(:page => nil).should be_a_kind_of(Array)
      @result.current_page.should == 1
    end

    it "returns an empty array if the page option is smaller than 1" do
      @result.paginate(:page => 0).should == []
    end

    it "returns an empty array if the page option is larger than total_pages" do
      @result.paginate(:page => @result.total_pages + 1).should == []
    end

  end

  describe ".previous_page" do

    it "should return nil if we are at page 1" do
      @result.paginate(:page => 1)
      @result.previous_page.should_not be
    end
  end

  describe ".next_page" do

    it "should return nil if there are no more pages" do
      @result.paginate(:page => 1)
      @result.next_page.should_not be
    end
  end

end
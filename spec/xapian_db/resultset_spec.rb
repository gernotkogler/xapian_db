# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XapianDb::Resultset do
  
  describe ".paginate(opts={})" do
    
    before :each do
      
      # Mock a Xapian search result (Xapian::Enquire)
      @enquiry = mock(Xapian::Enquire)
      mset     = mock(Xapian::MSet)
      match    = mock(Xapian::Match)
      
      match.stub!(:document).and_return(Xapian::Document.new)
      mset.stub!(:matches_estimated).and_return(1)
      mset.stub!(:matches).and_return([match])
      @enquiry.stub!(:mset).and_return(mset)
    end

    it "should return an empty array if the page parameters are beyond the resultset size" do
      result = XapianDb::Resultset.new(@enquiry)
      result.paginate(:page => 2, :per_page => 10).should == []
    end
    
    it "should return an array of Xapian documents if the page parameters are within the resultset size" do
      result = XapianDb::Resultset.new(@enquiry)
      result.paginate(:page => 1, :per_page => 10).should be_a_kind_of(Array)
      result.paginate(:page => 1, :per_page => 10).size.should == 1
      result.paginate(:page => 1, :per_page => 10).first.should be_a_kind_of(Xapian::Document)
    end

    
  end
  
end
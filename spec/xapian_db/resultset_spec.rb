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
      blueprint.field :name
    end

    @result = XapianDb::Resultset.new(enquiry)
  end
  
  describe ".paginate(opts={})" do
    
    it "should return an empty array if the page parameters are beyond the resultset size" do
      @result.paginate(:page => 2, :per_page => 10).should == []
    end
    
    it "should return an array of Xapian documents if the page parameters are within the resultset size" do
      @result.paginate(:page => 1, :per_page => 10).should be_a_kind_of(Array)
      @result.paginate(:page => 1, :per_page => 10).size.should == 1
      @result.paginate(:page => 1, :per_page => 10).first.should be_a_kind_of(Xapian::Document)
    end

    it "should decorate the returned Xapian documents with field accessors" do
      doc = @result.paginate(:page => 1, :per_page => 10).first
      doc.respond_to?(:name).should be_true
      doc.name.should == @name
    end
    
  end
  
end
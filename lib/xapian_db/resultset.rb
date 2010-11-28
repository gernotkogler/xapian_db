# encoding: utf-8

# The resultset holds a Xapian::Query object and allows paged access
# to the found documents.
# author Gernot Kogler

module XapianDb
  
  class Resultset
    
    attr_reader :size
    
    # Constructor
    # @param [Xapian::Enquire] a Xapian query result
    def initialize(enquiry)
      @enquiry = enquiry
      @size = enquiry.mset.matches_estimated
    end

    # Paginate the result
    def paginate(opts={})
      options = {:page => 1, :per_page => 10}.merge(opts)
      offset = (options[:page] - 1) * options[:per_page]
      return [] if offset > @size
      build_page(options[:page], options[:per_page])
    end
    
    private
    
    def build_page(page, per_page)
      docs = []
      result_window = @enquiry.mset(page - 1, per_page)
      result_window.matches.each do |match|
        docs << match.document
      end
      docs
    end
            
  end
  
end
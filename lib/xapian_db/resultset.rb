# encoding: utf-8

module XapianDb

  # The resultset encapsulates a Xapian::Query object and allows paged access
  # to the found documents.
  # The resultset is compatible with will_paginate.
  # @example Process the first page of a resultsest
  #   resultset.paginate(:page => 1, :per_page => 10).each do |doc|
  #     # do something with the xapian document
  #   end
  # @example Use the resultset and will_paginate in a view
  #   <%= will_paginate resultset %>
  # @author Gernot Kogler
  class Resultset

    # The number of documents found
    # @return [Integer]
    attr_reader :size

    # The number of pages
    # @return [Integer]
    attr_reader :total_pages

    # The current page
    # @return [Integer]
    attr_reader :current_page

    # The spelling corrected query (if a language is configured)
    # @return [String]
    attr_accessor :spelling_suggestion

    # Constructor
    # @param [Xapian::Enquire] enquiry a Xapian query result (see http://xapian.org/docs/apidoc/html/classXapian_1_1Enquire.html)
    # @param [Hash] options
    # @option options [Integer] :per_page (10) How many docs per page?
    # @option options [String] :spelling_suggestion (nil) The spelling corrected query (if a language is configured)
    def initialize(enquiry, options)
      @enquiry = enquiry
      # To get more accurate results, we pass the doc count to the mset method
      @size                = enquiry.mset(0, options[:db_size]).matches_estimated
      @spelling_suggestion = options[:spelling_suggestion]
      @per_page            = options[:per_page]
      @total_pages         = (@size / @per_page.to_f).ceil
      @current_page        = 1
    end

    # Paginate the result
    # @param [Hash] options Options for the persistent database
    # @option options [Integer] :page (1) The page to access
    def paginate(options={})
      @current_page = options[:page] ? options[:page].to_i : 1
      raise ArgumentError.new("page #{current_page} does not exist") if @current_page < 1 || @current_page > @total_pages
      build_page(@current_page)
    end

    # The previous page number
    # @return [Integer] The number of the previous page or nil, if we are at page 1
    def previous_page
      @current_page > 1 ? (@current_page - 1) : nil
    end

    # The next page number
    # @return [Integer] The number of the next page or nil, if we are at the last page
    def next_page
      @current_page < @total_pages ? (@current_page + 1): nil
    end

    private

    # Build a page of Xapian documents
    # @return [Array<Xapian::Document>] An array of xapian documents
    def build_page(page)
      docs = []
      offset = (page - 1) * @per_page
      return [] if offset > @size
      result_window = @enquiry.mset(offset, @per_page)
      result_window.matches.each do |match|
        docs << decorate(match.document)
      end
      docs
    end

    # Decorate a Xapian document with field accessors for each configured attribute
    def decorate(document)
      klass_name = document.values[0].value
      blueprint  = XapianDb::DocumentBlueprint.blueprint_for(Kernel.const_get(klass_name))
      document.extend blueprint.accessors_module
    end

  end

end
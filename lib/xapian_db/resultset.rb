# encoding: utf-8

module XapianDb

  # The resultset encapsulates a Xapian::Query object and allows paged access
  # to the found documents.
  # @example Process the first page of a resultsest
  #   resultset.paginate(:page => 1, :per_page => 10).each do |doc|
  #     # do something with the xapian document
  #   end
  # @author Gernot Kogler
  class Resultset

    # The number of documents found
    # @return [Integer]
    attr_reader :size

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
      @per_page = options[:per_page]
    end

    # Paginate the result
    # @param [Hash] opts Options for the persistent database
    # @option opts [Integer] :page (1) The page to access
    def paginate(opts={})
      options = {:page => 1}.merge(opts)
      build_page(options[:page])
    end

    private

    # Build a page of Xapian documents
    # @return [Array<Xapian::Document>] An array of xapian documents
    def build_page(page)
      page.nil? ? page = 1 : page = page.to_i
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
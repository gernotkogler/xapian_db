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
  class Resultset < Array

    # The number of hits
    # @return [Integer]
    attr_reader :hits

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
    # @param [Xapian::Enquire] enquiry a Xapian query result (see http://xapian.org/docs/apidoc/html/classXapian_1_1Enquire.html).
    #   Pass nil to get an empty result set.
    # @param [Hash] options
    # @option options [Integer] :db_size The current size (nr of docs) of the database
    # @option options [Integer] :limit The maximum number of documents to retrieve
    # @option options [Integer] :page (1) The page number to retrieve
    # @option options [Integer] :per_page (10) How many docs per page? Ignored if a limit option is given
    # @option options [String] :spelling_suggestion (nil) The spelling corrected query (if a language is configured)
    def initialize(enquiry, options={})

      @enquiry = enquiry
      return build_empty_resultset if @enquiry.nil?

      db_size              = options.delete :db_size
      limit                = options.delete :limit
      page                 = options.delete :page
      per_page             = options.delete :per_page
      @spelling_suggestion = options.delete :spelling_suggestion
      raise ArgumentError.new "unsupported options for resultset: #{options}" if options.size > 0
      raise ArgumentError.new "db_size option is required" unless db_size

      @hits         = enquiry.mset(0, db_size).matches_estimated
      limit       ||= @hits
      per_page    ||= limit
      @total_pages  = (limit / per_page.to_f).ceil
      page = page.nil? ? 1 : page.to_i
      offset = (page - 1) * per_page
      count  = offset + per_page < limit ? per_page : limit - offset
      raise ArgumentError.new "page #{@page} does not exist" if @hits > 0 && offset >= limit

      result_window = @enquiry.mset(offset, count)
      self.replace result_window.matches.map{|match| decorate(match).document}
      @current_page = page
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

    # Build an empty resultset
    def build_empty_resultset
      @hits         = 0
      @total_pages  = 0
      @current_page = 0
      self
    end

    # Decorate a Xapian match with field accessors for each configured attribute
    # @param [Xapian::Match] a match
    # @return [Xapian::Match] the decorated match
    def decorate(match)
      klass_name = match.document.values[0].value
      blueprint  = XapianDb::DocumentBlueprint.blueprint_for(Kernel.const_get(klass_name))
      match.document.extend blueprint.accessors_module
      match.document.instance_variable_set :@score, match.percent
      match
    end

  end

end
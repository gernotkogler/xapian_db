# encoding: utf-8

module XapianDb

  # The resultset encapsulates a Xapian::Query object and allows paged access
  # to the found documents.
  # The resultset is compatible with will_paginate and kaminari.
  # @example Process the first page of a resultsest
  #   resultset.paginate(:page => 1, :per_page => 10).each do |doc|
  #     # do something with the xapian document
  #   end
  # @example Use the resultset and will_paginate in a view
  #   <%= will_paginate resultset %>
  # @example Use the resultset and kaminari in a view
  #   <%= paginate resultset %>
  # @author Gernot Kogler
  class Resultset < Array

    include XapianDb::Utilities

    # The number of hits
    # @return [Integer]
    attr_reader :hits
    alias_method :total_count, :hits
    alias_method :total_entries, :hits

    # The number of pages
    # @return [Integer]
    attr_reader :total_pages
    alias_method :num_pages, :total_pages

    # The current page
    # @return [Integer]
    attr_reader :current_page

    # The spelling corrected query (if a language is configured)
    # @return [String]
    attr_accessor :spelling_suggestion

    # The number of records per page
    attr_reader :limit_value

    # Constructor
    # @param [Xapian::Enquire] enquiry a Xapian query result (see http://xapian.org/docs/apidoc/html/classXapian_1_1Enquire.html).
    #   Pass nil to get an empty result set.
    # @param [Hash] options
    # @option options [Integer] :db_size The current size (nr of docs) of the database
    # @option options [Integer] :limit The maximum number of documents to retrieve
    # @option options [Integer] :offset The index of the first result to retrieve
    # @option options [Integer] :page (1) The page number to retrieve
    # @option options [Integer] :per_page (10) How many docs per page? Ignored if a limit option is given
    # @option options [String] :spelling_suggestion (nil) The spelling corrected query (if a language is configured)
    def initialize(enquiry, options={})

      return build_empty_resultset if enquiry.nil?
      params               = options.dup
      db_size              = params.delete :db_size
      @spelling_suggestion = params.delete :spelling_suggestion
      limit                = params.delete :limit
      offset               = params.delete :offset
      page                 = params.delete :page
      per_page             = params.delete :per_page
      raise ArgumentError.new "unsupported options for resultset: #{params}" if params.size > 0
      raise ArgumentError.new "db_size option is required" unless db_size

      raise ArgumentError.new "impossible combination of parameters" unless per_page.nil? || limit.nil? || per_page == limit

      calculated_page = offset.nil? || limit.nil? ? nil : (offset.to_f / limit.to_f) + 1
      limit           = limit.nil? ? db_size : limit.to_i
      per_page        = per_page.nil? ? limit.to_i : per_page.to_i

      raise ArgumentError.new "impossible combination of parameters" unless offset.nil? || page.nil? || ((page - 1) * per_page) == offset

      page   = page.nil? ? (calculated_page.nil? ? 1 : calculated_page) : page.to_i
      offset = offset.nil? ? (page - 1) * per_page : offset.to_i
      count  = per_page < limit ? per_page : limit

      return build_empty_resultset if (page - 1) * per_page > db_size
      result_window = enquiry.mset(offset, count)
      @hits = result_window.matches_estimated
      return build_empty_resultset if @hits == 0

      self.replace result_window.matches.map{|match| decorate(match).document}
      @total_pages  = (@hits / per_page.to_f).ceil
      @current_page = (page == page.to_i) ? page.to_i : page
      @limit_value  = per_page
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

    # Build an empty resultset
    def build_empty_resultset
      @hits         = 0
      @total_pages  = 0
      @current_page = 0
      @limit_value  = 0
      self
    end

    # Decorate a Xapian match with field accessors for each configured attribute
    # @param [Xapian::Match] a match
    # @return [Xapian::Match] the decorated match
    def decorate(match)
      klass_name = match.document.values[0].value
      blueprint  = XapianDb::DocumentBlueprint.blueprint_for klass_name
      match.document.extend blueprint.accessors_module
      match.document.instance_variable_set :@score, match.percent
      match
    end

  end

end

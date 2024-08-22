# encoding: utf-8

module XapianDb

  # Parse a query expression and create a xapian query object
  # @author Gernot Kogler
  class QueryParser

    # The spelling corrected query (if a language is configured)
    # @return [String]
    attr_reader :spelling_suggestion

    # Constructor
    # @param [XapianDb::Database] database The database to query
    def initialize(database)
      @db = database

      # Set the parser options
      @query_flags = 0
      XapianDb::Config.query_flags.each { |flag| @query_flags |= flag }
    end

    # Parse an expression
    # @return [Xapian::Query] The query object (see http://xapian.org/docs/apidoc/html/classXapian_1_1Query.html)
    def parse(expression)
      return nil if expression.nil? || expression.strip.empty?
      parser            = Xapian::QueryParser.new
      parser.database   = @db.reader
      parser.default_op = Xapian::Query::OP_AND # Could be made configurable
      if XapianDb::Config.stemmer
        parser.stemmer           = XapianDb::Config.stemmer
        parser.stemming_strategy = Xapian::QueryParser::STEM_SOME
        parser.stopper           = XapianDb::Config.stopper
      end
      max_expansion = XapianDb::Config.set_max_expansion
      parser.set_max_expansion(max_expansion, Xapian::Query::WILDCARD_LIMIT_MOST_FREQUENT) if max_expansion

      # Add the searchable prefixes to allow searches by field
      # (like "name:Kogler")
      processors = [] # The reason for having a seemingly useless "processors" array is as follows:
      # We need to add a reference to the generated Xapian::XYValueRangeProcessor objects to the scope that calls parser.parse_query.
      # If we don't, the Ruby GC will often garbage collect the generated objects before parser.parse_query can be called,
      # which would free the memory of the corresponding C++ objects and result in segmentation faults upon calling parse_query.
      XapianDb::DocumentBlueprint.searchable_prefixes.each do |prefix|
        parser.add_prefix(prefix.to_s.downcase, "X#{prefix.to_s.upcase}")
        type_info = XapianDb::DocumentBlueprint.type_info_for(prefix)
        next if type_info.nil? || type_info == :generic
        value_number = XapianDb::DocumentBlueprint.value_number_for(prefix)
        case type_info
          when :date
            processor = Xapian::DateValueRangeProcessor.new(value_number, "#{prefix}:")
            processors << processor
            parser.add_valuerangeprocessor(processor)
          when :number
            processor = Xapian::NumberValueRangeProcessor.new(value_number, "#{prefix}:")
            processors << processor
            parser.add_valuerangeprocessor(processor)
          when :string
            processor = Xapian::StringValueRangeProcessor.new(value_number, "#{prefix}:")
            processors << processor
            parser.add_valuerangeprocessor(processor)
        end
      end
      query = parser.parse_query(expression, @query_flags)
      @spelling_suggestion = parser.get_corrected_query_string.force_encoding("UTF-8")
      @spelling_suggestion = nil if @spelling_suggestion.empty?
      query
    end

  end

end

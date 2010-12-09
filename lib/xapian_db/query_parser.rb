# encoding: utf-8

module XapianDb

  # Parse a query expression and create a xapian query object
  # @author Gernot Kogler
  class QueryParser

    # Constructor
    # @param [XapianDb::Database] database The database to query
    def initialize(database)
      @db = database

      # Set the parser options
      @query_flags = 0
      @query_flags |= Xapian::QueryParser::FLAG_WILDCARD         # enable wildcards
      @query_flags |= Xapian::QueryParser::FLAG_BOOLEAN          # enable boolean operators
      @query_flags |= Xapian::QueryParser::FLAG_BOOLEAN_ANY_CASE # enable case insensitive boolean operators
    end

    # Parse an expression
    # @return [Xapian::Query] The query object (see http://xapian.org/docs/apidoc/html/classXapian_1_1Query.html)
    def parse(expression)
      parser            = Xapian::QueryParser.new
      parser.database   = @db.reader
      parser.default_op = Xapian::Query::OP_AND # Could be made configurable
      # TODO: Setup stopper, stemmer, defaults and fields

      # Add the searchable prefixes to allow searches by field
      # (like "name:Kogler")
      XapianDb::DocumentBlueprint.searchable_prefixes.each{|prefix| parser.add_prefix(prefix.to_s.downcase, "X#{prefix.to_s.upcase}") }
      parser.parse_query(expression, @query_flags)
    end

  end

end
# encoding: utf-8

# Parse a query expression and convert it to Xapian Query arguments
# @author Gernot Kogler

module XapianDb
  
  class QueryParser
    
    def initialize(database)
      @db = database
      
      # Set the parser options
      @query_flags = 0
      @query_flags |= Xapian::QueryParser::FLAG_WILDCARD # enable wildcards
      @query_flags |= Xapian::QueryParser::FLAG_BOOLEAN
      @query_flags |= Xapian::QueryParser::FLAG_BOOLEAN_ANY_CASE
    end
    
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
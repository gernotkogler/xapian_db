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
    end
    
    def parse(expression)
      parser = Xapian::QueryParser.new
      parser.database = @db.reader
      # TODO: Setup stopper, stemmer, defaults and fields
      parser.parse_query(expression, @query_flags)
    end
    
  end
  
end
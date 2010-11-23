require 'digest/sha1'
require 'rubygems'
require 'xapian'

module XapianDb

  # Create a database. Overwrites an existing database on disk, if
  # option :in_memory is set to false.
  def self.create_db(options = {})
    if options[:path] 
      PersistentDatabase.new(:path => options[:path], :create => true) 
    else
      InMemoryDatabase.new
    end
  end
  
end

require File.dirname(__FILE__) + '/xapian_db/database'

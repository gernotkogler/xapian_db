# encoding: utf-8

# This example shows the most basic way to use xapian_db
# To run the example, please install the xapian_db gem first

require 'rubygems'
require 'xapian_db'

puts "Setting up the demo..."

# 1: Open an in memory database
db = XapianDb.create_db

# 2: Define a class which should get indexed; we define a class that
# could be an ActiveRecord or Datamapper Domain class
class People
  
  attr_accessor :id, :name, :first_name
  
  def initialize(data)
    @id, @name, @first_name = data[:id], data[:name], data[:first_name]
  end
  
end

# 3: Configure the generic adapter with a unique key expression
XapianDb::Adapters::GenericAdapter.unique_key do
  "#{self.class}-#{self.id}"
end

# 4: Define a document blueprint for our class; the blueprint describes
# the structure of all documents for our class
XapianDb::DocumentBlueprint.setup(People) do |blueprint|
  blueprint.field :name
  blueprint.field :first_name

  blueprint.text :name
  blueprint.text :first_name
end

# 5: Let's create some objects
person_1 = People.new(:id => 1, :name => "Kogler", :first_name => "Gernot")
person_2 = People.new(:id => 2, :name => "Frey",   :first_name => "Daniel")
person_3 = People.new(:id => 3, :name => "Garaio", :first_name => "Thomas")

# 6: Now add them to the database
indexer = XapianDb::Indexer.new(XapianDb::DocumentBlueprint.blueprint_for(People))
db.store_doc(indexer.build_document_for(person_1))
db.store_doc(indexer.build_document_for(person_2))
db.store_doc(indexer.build_document_for(person_3))

# 7: Now find the gem author ;-)
puts "Searching for Gernot..."
results = db.search("Gernot")
puts "We found #{results.size} documents"
puts "And the first document looks like this:"
page = results.paginate(:page => 1)
doc  = page.first
puts "name: #{doc.name}"
puts "first name: #{doc.first_name}"

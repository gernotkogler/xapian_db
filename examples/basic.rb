# encoding: utf-8

# This example shows the most basic way to use xapian_db
# To run the example, please install the xapian_db gem first

require 'rubygems'
require 'date'
require 'xapian_db'

puts "Setting up the demo..."

XapianDb::Config.setup do |config|
  config.adapter :generic
end

# 1: Open an in memory database
db = XapianDb.create_db

# 2: Define a class which should get indexed; we define a class that
# could be an ActiveRecord or Datamapper Domain class
class Person
  # If you are using inheritance hierarchies among indexed classes outside of ActiveRecord,
  # using DescendantsTracker helps with rebuilding the Xapian index for a given class and all its subclasses.
  extend DescendantsTracker

  attr_accessor :id, :name, :first_name, :date_of_birth

  def initialize(data)
    @id, @name, @first_name, @date_of_birth = data[:id], data[:name], data[:first_name], data[:date_of_birth]
  end

end

# 3: Configure the generic adapter with a unique key expression
XapianDb::Adapters::GenericAdapter.unique_key do
  "#{self.class}-#{self.id}"
end

# 4: Define a document blueprint for our class; the blueprint describes
# the structure of all documents for our class. Attribute values can
# be accessed later for each retrieved doc. Attributes are indexed
# by default.
XapianDb::DocumentBlueprint.setup(:Person) do |blueprint|
  blueprint.attribute :name
  blueprint.attribute :first_name
  blueprint.attribute :date_of_birth, :as => :date
end

# 5: Let's create some objects
person_1 = Person.new :id => 1, :name => "Doe",    :first_name => "John",  :date_of_birth => Date.new(1970, 2, 16)
person_2 = Person.new :id => 2, :name => "Smith",  :first_name => "Frank", :date_of_birth => Date.new(1966, 5, 2)
person_3 = Person.new :id => 3, :name => "Willis", :first_name => "Frank", :date_of_birth => Date.new(1968, 11, 4)

# 6: Now add them to the database
blueprint = XapianDb::DocumentBlueprint.blueprint_for(:Person)
indexer   = XapianDb::Indexer.new(db, blueprint)
db.store_doc(indexer.build_document_for(person_1))
db.store_doc(indexer.build_document_for(person_2))
db.store_doc(indexer.build_document_for(person_3))

# 7: Now find a person
puts "Searching for John..."
results = db.search("John")
puts "We found #{results.size} documents"
puts "And the first document looks like this:"
doc  = results.first
puts "name: #{doc.name}"
puts "first name: #{doc.first_name}"
puts "date of birth: #{doc.date_of_birth.strftime("%d.%m.%Y")}"

# Get all facets (classes) for a search expression
facets = db.facets(:first_name, "Frank")
puts "facets:"
facets.each do |value, count|
  puts "#{value}: #{count} hits"
end

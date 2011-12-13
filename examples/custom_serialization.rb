# encoding: utf-8

# This example shows how to implement and use a custom
# serialization mechanism for attributes

require 'rubygems'
require 'xapian_db'

# 1: Define a custom codec. As an example, we define a codec that serializes arrays
# as csv strings. Does not make much sense but demonstrates how to implement such a thing
module XapianDb
  class TypeCodec
    class CsvCodec

      def self.encode(array)
        array.join(";")
      end

      def self.decode(csv_string)
        csv_string.split(";")
      end

    end
  end
end

# 2: Open an in memory database
db = XapianDb.create_db

# 3: Define a class which should get indexed
class ArrayContainer

  attr_accessor :id, :array

  def initialize(data)
    @id, @array = data[:id], data[:array]
  end

end

# 4: Configure the generic adapter with a unique key expression
XapianDb::Adapters::GenericAdapter.unique_key do
  "#{self.class}-#{self.id}"
end

# 6: Define a document blueprint for our class
XapianDb::DocumentBlueprint.setup(:ArrayContainer) do |blueprint|
  blueprint.attribute :array, :as => :csv
end

# 7: Let's create an object
object = ArrayContainer.new :id => 1, :array => %w(this is an array)
puts "storing object wit array #{object.array}..."

# 8: add them to the database
blueprint = XapianDb::DocumentBlueprint.blueprint_for(:ArrayContainer)
indexer   = XapianDb::Indexer.new(db, blueprint)
db.store_doc(indexer.build_document_for(object))

# 9: Get the document
puts "Loading the doc..."
results = db.search("this")

doc = results.first
puts "The raw document value looks like this: #{doc.values[1].value}"
puts "The deserialized array looks like this: #{doc.array}"

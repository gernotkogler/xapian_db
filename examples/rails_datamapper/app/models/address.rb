class Address

  include DataMapper::Resource

  property :id,     Serial
  property :street, String
  property :city,   String
  property :zip,    String

  has n, :people

end

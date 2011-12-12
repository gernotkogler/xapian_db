class Person

  include DataMapper::Resource

  property :id,            Serial
  property :name,          String
  property :first_name,    String
  property :date_of_birth, Date
  property :language,      String
  property :notes,         Text

  belongs_to :address

end

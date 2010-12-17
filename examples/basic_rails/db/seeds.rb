# Create random addresses and people using the forgery gem

puts "Creating test data, be patient..."

# 1: cleanup
Person.connection.execute("delete from people")
Person.connection.execute("delete from sqlite_sequence where name='people'")
Address.connection.execute("delete from addresses")
Address.connection.execute("delete from sqlite_sequence where name='addresses'")

# 2: create 1000 addresses
1000.times do
  Address.create :street => Forgery::Address.street_address,
                 :zip    => Forgery::Address.zip,
                 :city   => Forgery::Address.city
end

# 3: create 10'000 people
languages = %w(da nl en fi fr de hu it nb nn no pt ro ru es sv tr)
1000.times do
  Person.create :name          => Forgery::Name.last_name,
                :first_name    => Forgery::Name.first_name,
                :date_of_birth => Forgery::Date.date(:future => false, :min_delta => 7200, :max_delta => 30000),
                :language      => languages[Forgery::Basic.number(:at_least => 0, :at_most => languages.size - 1)],
                :address_id    => Forgery::Basic.number(:at_least => 1, :at_most => 1000),
                :notes         => Forgery::LoremIpsum.words(Forgery::Basic.number(:at_least => 1, :at_most => 50))
end

puts "The database is now loaded with test records"

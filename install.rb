require 'ftools'

source = File.join(File.dirname(__FILE__), '/rails_generators/xapian_db/templates/xapian_db.rb')
destination = "#{Rails.root}/config/initializers/xapian_db.rb"
unless File.exist? destination
  puts "Adding config/initializers/xapian_db.rb"
  File.copy(source, destination)
end

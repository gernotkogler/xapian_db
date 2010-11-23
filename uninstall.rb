path = "#{Rails.root}/config/initializers/xapian_db.rb"
if File.exist? path
  puts "Removing xapian_db.rb initializer."
  File.delete(path)
end

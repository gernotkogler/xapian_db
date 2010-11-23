require 'rubygems'
require 'fileutils'
require 'simplecov'

SimpleCov.start do
  add_group "Basic", "lib/xapian_db"
end

require File.dirname(__FILE__) + '/../lib/xapian_db'

require 'rubygems'
require 'spec'
require 'fileutils'
require File.dirname(__FILE__) + '/../lib/xapian_db'

Spec::Runner.configure do |config|
  config.mock_with :rr
  config.before(:each) do
    XapianDb.setup(:database_path => File.dirname(__FILE__) + '/tmp/xapiandb')
    XapianDb.remove_database
  end
end

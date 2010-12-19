require 'rubygems'
require 'fileutils'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_group "Basic", "lib/xapian_db"
end

require File.dirname(__FILE__) + '/../lib/xapian_db'
require File.dirname(__FILE__) + '/basic_mocks'
require File.dirname(__FILE__) + '/orm_mocks'
require File.dirname(__FILE__) + '/beanstalk_mock'

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true
  config.before(:each) do
    XapianDb::Adapters::GenericAdapter.unique_key do
      "#{self.class}-#{self.id}"
    end
    ActiveRecordObject.reset
    DatamapperObject.reset
  end
end

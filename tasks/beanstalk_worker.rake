# encoding: utf-8

# This rake task is built to run within a Rails application and is the
# backend worker to serialize the index updates to a xapian database.
# Remember to install beanstalkd and configure the beanstalk-client gem
# in your Gemfile

require "#{Rails.root}/config/environment"
require "xapian_db"
require 'yaml'

namespace :xapian_db do

  desc "Run the beanstalk worker process to update the xapian index"
  task :beanstalk_worker do

    url = XapianDb::Config.beanstalk_daemon_url
    beanstalk = Beanstalk::Pool.new([url])
    worker    = XapianDb::IndexWriters::BeanstalkWorker.new
    puts "XapianDb beanstalk worker is serving on #{url}..."
    loop do
      job = beanstalk.reserve
      begin
        params = YAML::load job.body
        Rails.logger.info "XapianDb beanstalk worker: executing task #{params}"
        task = params.delete :task
        worker.send task, params
      rescue Exception => ex
        Rails.logger.error "XapianDb beanstalk worker: could not process #{job.body} (#{ex})"
      end
      job.delete
    end

  end
end
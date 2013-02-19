# encoding: utf-8

# Mock for the beanstalk-client gem
# @author Gernot Kogler

module Beanstalk

  class Pool

    def initialize(*args)
    end

    def put(command)
      worker = XapianDb::IndexWriters::BeanstalkWorker.new
      params = JSON.parse(command).symbolize_keys!
      task = params.delete :task
      worker.send task, params
    end

  end
end

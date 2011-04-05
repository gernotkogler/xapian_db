require 'rails/generators'

module XapianDb
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      desc "Creates a beanstalk worker script."

      def copy_script
        copy_file "beanstalk_worker", "script/beanstalk_worker"
        chmod "script/beanstalk_worker", 0755
      end

    end
  end
end
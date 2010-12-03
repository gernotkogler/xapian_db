# encoding: utf-8

# Configuration for a rails app
# @author Gernot Kogler

require 'xapian_db'
require 'rails'

module XapianDb
  class Railtie < ::Rails::Railtie

    config.before_configuration do

      # Read the database configuration file if there is one
      config_file_path = "#{Rails.root}/config/xapian_db.yml"
      if File.exist?(config_file_path)
        db_config = YAML::load_file config_file_path
        env_config = db_config[Rails.env]
        @database_path = env_config["database"]
      else
        # Set the default database path
        Rails.env == "test" ? @database_path = ":memory:" : @database_path = "db/xapian_db/#{Rails.env}"
      end
      
      # Do the configuration
      XapianDb::Config.setup do |config|
        if @database_path == ":memory:"
          config.database = XapianDb.create_db
        else
          unless File.exist?(@database_path)
            temp = XapianDb.create_db :path => @database_path
            temp = nil
            GC.start # Release the write lock on the database
          end
          config.database = XapianDb.open_db :path => @database_path
        end
      end
      
    end
    
  end
end
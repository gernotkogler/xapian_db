# encoding: utf-8

require 'xapian_db'
require 'rails'

module XapianDb

  # Configuration for a rails app
  # @author Gernot Kogler
  class Railtie < ::Rails::Railtie

    config.before_configuration do

      # Read the database configuration file if there is one
      config_file_path = "#{Rails.root}/config/xapian_db.yml"
      if File.exist?(config_file_path)
        db_config = YAML::load_file config_file_path
        env_config = db_config[Rails.env]
        database_path = env_config["database"] || ":memory:"
        adapter       = env_config["adapter"]  || :active_record
        writer        = env_config["writer"]   || :direct
      else
        # No config file, set the defaults
        Rails.env == "test" ? database_path = ":memory:" : database_path = "db/xapian_db/#{Rails.env}"
        adapter = :active_record
        writer  = :direct
      end

      # Do the configuration
      XapianDb::Config.setup do |config|
        if database_path == ":memory:"
          config.database :memory
        else
          config.database database_path
        end
        config.adapter adapter.to_sym
        config.writer writer.to_sym
        config.language(env_config["language"]) if env_config["language"]
      end

    end

  end
end
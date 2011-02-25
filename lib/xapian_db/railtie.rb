# encoding: utf-8

require 'xapian_db'
require 'rails'

module XapianDb

  # Configuration for a rails app
  # @author Gernot Kogler
  class Railtie < ::Rails::Railtie

    # Require our rake tasks
    rake_tasks do
      load "#{File.dirname(__FILE__)}/../../tasks/beanstalk_worker.rake"
    end

    config.before_configuration do

      # Read the database configuration file if there is one
      config_file_path = "#{Rails.root}/config/xapian_db.yml"
      if File.exist?(config_file_path)
        db_config = YAML::load_file config_file_path
        env_config = db_config[Rails.env]
        env_config ? configure_from(env_config) : configure_defaults
      else
        # No config file, set the defaults
        configure_defaults
      end

      # Do the configuration
      XapianDb::Config.setup do |config|
        if @database_path == ":memory:"
          config.database :memory
        else
          config.database File.expand_path @database_path
        end
        config.adapter @adapter.to_sym
        config.writer @writer.to_sym
        config.beanstalk_daemon_url @beanstalk_daemon
        config.language @language
      end

    end

    config.to_prepare do

      # Load a blueprint config if there is one
      blueprints_file_path = "#{Rails.root}/config/xapian_blueprints.rb"
      load blueprints_file_path if File.exist?(blueprints_file_path)
    end

  private

  # use the config options from the config file
  def self.configure_from(env_config)
    @database_path    = env_config["database"] || ":memory:"
    @adapter          = env_config["adapter"]  || :active_record
    @writer           = env_config["writer"]   || :direct
    @beanstalk_daemon = env_config["beanstalk_daemon"]
    @language         = env_config["language"]
  end

  # set default config options
  def self.configure_defaults
    Rails.env == "test" ? @database_path = ":memory:" : @database_path = "db/xapian_db/#{Rails.env}"
    @adapter          = :active_record
    @writer           = :direct
    @beanstalk_daemon = nil
    @language         = :en
  end

  end
end
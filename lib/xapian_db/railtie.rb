# encoding: utf-8

require 'xapian_db'
require 'rails'

module XapianDb

  # Configuration for a rails app
  # @author Gernot Kogler
  class Railtie < ::Rails::Railtie

    # require our rake tasks
    rake_tasks do
      load "#{File.dirname(__FILE__)}/../../tasks/xapian_rebuild_index.rake"
    end

    # require our generators
    generators do
      require "#{File.dirname(__FILE__)}/../generators/install_generator.rb"
    end

    initializer "xapian_db.active_record" do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend XapianDb::ModelExtenders::ActiveRecord
      end
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
        config.adapter @adapter.try(:to_sym)
        config.writer @writer.try(:to_sym)
        config.beanstalk_daemon_url @beanstalk_daemon
        config.resque_queue @resque_queue
        config.language @language.try(:to_sym)
        config.term_min_length @term_min_length
        if @enable_phrase_search
          config.enable_phrase_search
        else
          config.disable_phrase_search
        end
        config.term_splitter_count @term_splitter_count
        @enabled_query_flags.each  { |flag| config.enable_query_flag flag }
        @disabled_query_flags.each { |flag| config.disable_query_flag flag }
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
      @database_path        = env_config["database"] || ":memory:"
      @adapter              = env_config["adapter"]  || :active_record
      @writer               = env_config["writer"]   || :direct
      @beanstalk_daemon_url = env_config["beanstalk_daemon"]
      @resque_queue         = env_config["resque_queue"]
      @language             = env_config["language"]
      @term_min_length      = env_config["term_min_length"]
      @enable_phrase_search = env_config["enable_phrase_search"] == true
      @term_splitter_count  = env_config["term_splitter_count"] || 0

      if env_config["enabled_query_flags"]
        @enabled_query_flags = []
        env_config["enabled_query_flags"].split(",").each { |flag_name| @enabled_query_flags << const_get("Xapian::QueryParser::%s" % flag_name.strip) }
      else
        @enabled_query_flags = [ Xapian::QueryParser::FLAG_WILDCARD,
                                 Xapian::QueryParser::FLAG_BOOLEAN,
                                 Xapian::QueryParser::FLAG_BOOLEAN_ANY_CASE,
                                 Xapian::QueryParser::FLAG_SPELLING_CORRECTION
                               ]
      end

      if env_config["disabled_query_flags"]
        @disabled_query_flags = []
        env_config["disabled_query_flags"].split(",").each { |flag_name| @disabled_query_flags << const_get("Xapian::QueryParser::%s" % flag_name.strip) }
      else
        @disabled_query_flags = []
      end
    end

    # set default config options
    def self.configure_defaults
      Rails.env == "test" ? @database_path = ":memory:" : @database_path = "db/xapian_db/#{Rails.env}"
      @adapter              = :active_record
      @writer               = :direct
      @beanstalk_daemon     = nil
      @term_min_length      = 1
      @enable_phrase_search = false
      @term_splitter_count  = 0
      @enabled_query_flags  = [ Xapian::QueryParser::FLAG_WILDCARD,
                                Xapian::QueryParser::FLAG_BOOLEAN,
                                Xapian::QueryParser::FLAG_BOOLEAN_ANY_CASE,
                                Xapian::QueryParser::FLAG_SPELLING_CORRECTION
                              ]
    end
  end
end

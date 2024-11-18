require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe 'test' do
  class Railtie
    def self.configure_from(env_config)
      @database_path        = env_config["database"] || ":memory:"
      @adapter              = env_config["adapter"]  || :active_record
      @writer               = env_config["writer"]   || :direct
      @beanstalk_daemon_url = env_config["beanstalk_daemon"]
      @resque_queue         = env_config["resque_queue"]
      @sidekiq_queue        = env_config["sidekiq_queue"]
      @language             = env_config["language"]
      @term_min_length      = env_config["term_min_length"]
      @enable_phrase_search = env_config["enable_phrase_search"] == true
      @term_splitter_count  = env_config["term_splitter_count"] || 0
      @set_max_expansion    = env_config["set_max_expansion"]
      @sidekiq_retry        = env_config["sidekiq_retry"]
    end
  end
  let(:yaml_content_with_erb) do
    <<-YAML
      development:
        adapter: <%= ENV.fetch('XAPIAN_DB_ADAPTER', 'fallback_adapter') %>

      test:
        adapter: xapian
    YAML
  end

  around do |example|
    Tempfile.open('xapian_db.yml') do |file|
      file.write(yaml_content_with_erb)
      file.rewind
      @config_file_path = file.path

      example.run
    end
  end

  context 'when loading adapter from a temporary YAML file with ERB' do
    it 'loads the generic adapter based on environment variable' do
      ENV['XAPIAN_DB_ADAPTER'] = 'generic'

      db_config = if YAML.respond_to?(:unsafe_load_file)
                    YAML.unsafe_load(ERB.new(File.read(@config_file_path)).result)
                  else
                    YAML.safe_load(ERB.new(File.read(@config_file_path)).result, aliases: true)
                  end

      Railtie.configure_from(db_config['development'])

      expect(Railtie.instance_variable_get(:@adapter)).to eq('generic')
    end

    it 'loads the xapian adapter based on direct value' do
      db_config = if YAML.respond_to?(:unsafe_load_file)
                    YAML.unsafe_load(ERB.new(IO.read(@config_file_path)).result)
                  else
                    YAML.safe_load(ERB.new(IO.read(@config_file_path)).result, aliases: true)
                  end

      Railtie.configure_from(db_config['test'])

      expect(Railtie.instance_variable_get(:@adapter)).to eq('xapian')
    end
  end
end

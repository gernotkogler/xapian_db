require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'yaml'
require 'erb'
require 'tempfile'

describe '.adapter' do
  let(:yaml_content_with_erb) do
    <<-YAML
      development:
        adapter: <%= ENV.fetch('XAPIAN_DB_ADAPTER', 'generic') %>

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
                    YAML.unsafe_load(ERB.new(File.read(@config_file_path)).result, aliases: true)
                  else
                    YAML.safe_load(ERB.new(File.read(@config_file_path)).result, aliases: true)
                  end

      env_config = db_config['development']

      expect(env_config['adapter']).to eq('generic')
      ENV.delete('XAPIAN_DB_ADAPTER')
    end

    it 'loads the xapian adapter based on direct value' do
      db_config = if YAML.respond_to?(:unsafe_load_file)
                    YAML.unsafe_load(ERB.new(IO.read(@config_file_path)).result, aliases: true)
                  else
                    YAML.safe_load(ERB.new(IO.read(@config_file_path)).result, aliases: true)
                  end

      env_config = db_config['test']

      expect(env_config['adapter']).to eq('xapian')
    end
  end
end

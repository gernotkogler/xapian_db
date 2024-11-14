require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/xapian_db/railtie.rb')

RSpec.describe 'test' do
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

      XapianDb::Railtie.configure_from(db_config['development'])

      expect(XapianDb::Railtie.instance_variable_get(:@adapter)).to eq('generic')
    end

    it 'loads the xapian adapter based on direct value' do
      db_config = if YAML.respond_to?(:unsafe_load_file)
                    YAML.unsafe_load(ERB.new(IO.read(@config_file_path)).result)
                  else
                    YAML.safe_load(ERB.new(IO.read(@config_file_path)).result, aliases: true)
                  end

      XapianDb::Railtie.configure_from(db_config['test'])

      expect(XapianDb::Railtie.instance_variable_get(:@adapter)).to eq('xapian')
    end
  end
end

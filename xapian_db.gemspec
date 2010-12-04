# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xapian_db}
  s.version = "0.3.0"
  s.add_dependency('progressbar', '>= 0.9.0')
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gernot kogler"]
  s.date = %q{2010-12-1}
  s.description = %q{Ruby library to use a Xapian db as a key/value store with high performance fulltext search}
  s.email = %q{gernot.kogler (at) garaio (dot) com}
  s.extra_rdoc_files = ["CHANGELOG"]
  s.files = ["CHANGELOG", "lib/xapian_db.rb", "lib/xapian_db/railtie.rb", "lib/xapian_db/config.rb", "lib/xapian_db/index_writers/direct_writer.rb", "lib/xapian_db/database.rb", "lib/xapian_db/document_blueprint.rb", "lib/xapian_db/indexer.rb", "lib/xapian_db/adapters/generic_adapter.rb", "lib/xapian_db/adapters/datamapper_adapter.rb", "lib/xapian_db/adapters/active_record_adapter.rb", "lib/xapian_db/query_parser.rb", "lib/xapian_db/resultset.rb"]
  s.homepage = %q{http://github.com/gernotkogler/xapian_db}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Xapian-DB", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Ruby library to use a Xapian db as a key/value store with high performance fulltext search}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

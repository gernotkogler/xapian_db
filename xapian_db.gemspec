# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name         = %q{xapian_db}
  s.version      = "1.3.6"
  s.authors      = ["Gernot Kogler"]
  s.license      = 'MIT'
  s.summary      = %q{Ruby library to use a Xapian db as a key/value store with high performance fulltext search}
  s.description  = %q{XapianDb is a ruby gem that combines features of nosql databases and fulltext indexing. It is based on Xapian, an efficient and powerful indexing library}
  s.email        = %q{gernot.kogler (at) garaio (dot) com}
  s.homepage     = %q{https://github.com/garaio/xapian_db}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Xapian-DB", "--main", "README.rdoc"]

  s.required_rubygems_version = ">=1.3.6"

  s.add_dependency "daemons", ">= 1.0.10"

  s.add_development_dependency "guard"
  s.add_development_dependency "rspec",            ">= 2.3.1"
  s.add_development_dependency "simplecov",        ">= 0.3.7"
  s.add_development_dependency "beanstalk-client", ">= 1.1.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "ruby-progressbar"
  s.add_development_dependency "resque",           ">= 1.19.0"
  s.add_development_dependency "sidekiq",          ">= 2.13.0"
  s.add_development_dependency "xapian-ruby",      "= 1.2.21"
  s.add_development_dependency "pry-rails"

  s.files         = Dir.glob("lib/**/*") + Dir.glob("tasks/*") + Dir.glob("xapian_source/*") + %w(LICENSE README.rdoc CHANGELOG.md Rakefile)
  s.require_path  = "lib"
end

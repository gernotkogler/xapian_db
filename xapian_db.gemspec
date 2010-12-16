# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name         = %q{xapian_db}
  s.version      = "0.4.1"
  s.authors      = ["Gernot Kogler"]
  s.summary      = %q{Ruby library to use a Xapian db as a key/value store with high performance fulltext search}
  s.description  = %q{Ruby library to use a Xapian db as a key/value store with high performance fulltext search}
  s.email        = %q{gernot.kogler (at) garaio (dot) com}
  s.homepage     = %q{https://github.com/garaio/xapian_db}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Xapian-DB", "--main", "README.rdoc"]

  s.required_rubygems_version = ">=1.3.6"

  s.add_development_dependency "rspec", ">= 2.1.0"
  s.add_development_dependency "simplecov", ">= 0.3.2"

   s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.rdoc CHANGELOG.md)
   s.require_path  = "lib"
end

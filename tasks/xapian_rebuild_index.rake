# encoding: utf-8

require "#{Rails.root}/config/environment"
require "xapian_db"

namespace :xapian do
  desc "rebuild the xapian index"
  task :reindex do
    XapianDb.rebuild_xapian_index :verbose => true
  end
end
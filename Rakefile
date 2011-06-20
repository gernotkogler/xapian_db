# encoding: utf-8
# Install the xapian binaries into the lib folder of the gem

require 'rbconfig'
c = Config::CONFIG

def system!(cmd)
	puts cmd
	system(cmd) or raise
end

ver = '1.2.6'
source_dir = 'xapian_source'
core = "xapian-core-#{ver}"
bindings = "xapian-bindings-#{ver}"
xapian_config = "#{Dir.pwd}/#{core}/xapian-config"

task :default do
	[core,bindings].each do |x|
		system! "tar -xzvf #{source_dir}/#{x}.tar.gz"
	end

	prefix = Dir.pwd
	ENV['LDFLAGS'] = "-R#{prefix}/lib"

	system! "mkdir -p lib"

	Dir.chdir core do
		system! "./configure --prefix=#{prefix} --exec-prefix=#{prefix}"
		system! "make clean all"
		system! "cp -r .libs/* ../lib/"
	end

	Dir.chdir bindings do
		ENV['RUBY'] ||= "#{c['bindir']}/#{c['RUBY_INSTALL_NAME']}"
		ENV['XAPIAN_CONFIG'] = xapian_config
		system! "./configure --prefix=#{prefix} --exec-prefix=#{prefix} --with-ruby"
		system! "make clean all"
	end

  system! "cp -r #{bindings}/ruby/.libs/_xapian.* lib"
  system! "cp #{bindings}/ruby/xapian.rb lib"

  system! "rm lib/*.a"
  system! "rm lib/*.la"
  system! "rm lib/*.lai"

  system! "rm -R #{bindings}"
  system! "rm -R #{core}"
  system! "rm -R #{source_dir}"

end

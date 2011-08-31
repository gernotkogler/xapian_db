# This Gemfile is only needed to run the test suite.
# If you haven't already, install xapian and the ruby bindings for xapian.
# Those binaries are inclued in the packaged gem so you have to do these
# steps only to run the test suite:
#
# curl -O http://oligarchy.co.uk/xapian/1.2.4/xapian-core-1.2.4.tar.gz
# tar xzvf xapian-core-1.2.3.tar.gz
# cd xapian-core-1.2.3
# ./configure --prefix=/usr/local
# make
# sudo make install
#
# curl -O http://oligarchy.co.uk/xapian/1.2.4/xapian-bindings-1.2.4.tar.gz
# tar xzvf xapian-bindings-1.2.3.tar.gz
# cd xapian-bindings-1.2.3
# ./configure --prefix=/usr/local XAPIAN_CONFIG=/usr/local/bin/xapian-config
# make
# sudo make install

source 'http://rubygems.org'

gem "rspec", ">= 2.1.0"
gem 'simplecov', ">= 0.3.2" # Will install simplecov-html as a dependency
gem "beanstalk-client"
gem "progressbar"
gem 'ruby-debug19'

# Testing support
gem 'guard-rspec'
gem 'growl'
gem 'rb-fsevent'
gem 'xapian-ruby'

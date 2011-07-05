source "http://rubygems.org"

# Specify your gem's dependencies in rhocrm.gemspec
gemspec
gem 'rake'

platforms :jruby do
  gem 'jdbc-sqlite3', :require => false
  gem 'dbi'
  gem 'dbd-jdbc', :require => 'dbd/Jdbc'
  gem 'jruby-openssl'
end

platforms :ruby do
  gem 'sqlite3'
end

group :test do
  gem 'rspec', '~>2.5.0', :require => 'spec'
  gem 'rcov', '~>0.9.8'
  gem 'webmock'
end

#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.require

ROOT_PATH = File.expand_path(File.dirname(__FILE__))

if ENV['DEBUG'] == 'yes'
  ENV['APP_TYPE'] = 'rhosync'
  ENV['ROOT_PATH'] = ROOT_PATH
  require 'debugger'
end

require 'rhoconnect/server'
require 'rhoconnect/web-console/server'
require 'resque/server'

# Rhoconnect server flags
#Rhoconnect::Server.enable  :stats
Rhoconnect::Server.disable :run
Rhoconnect::Server.disable :clean_trace
Rhoconnect::Server.enable  :raise_errors
Rhoconnect::Server.set     :secret,      '9cc991a64c0cc5b5d9d4f0a4fa5759d75ce0007c6faeca098d41bba9b0a7c1f0af4986d10a11e71a7d56874b07e86fba03a1dbbe53ff324912397c8930ca8ba0'
Rhoconnect::Server.set     :root,        ROOT_PATH
Rhoconnect::Server.use     Rack::Static, :urls => ['/data'], :root => Rhoconnect::Server.root

# Load our rhoconnect application
require './application'

# Setup the url map
run Rack::URLMap.new \
	'/'         => Rhoconnect::Server.new,
	'/resque'   => Resque::Server.new, # If you don't want resque frontend, disable it here
	'/console'  => RhoconnectConsole::Server.new # If you don't want rhoconnect frontend, disable it here
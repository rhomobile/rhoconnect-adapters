require 'rubygems'
require 'rspec'
require 'templater/spec/helpers'
require File.join(File.dirname(__FILE__),'..','spec_helper')

RSpec.configure do |config|
  config.include Templater::Spec::Helpers
end
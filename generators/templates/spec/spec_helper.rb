require 'rubygems'

# Set environment to test
ENV['RHO_ENV'] = 'test'
ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..'))

require 'bundler'
Bundler.require(:default, ENV['RHO_ENV'].to_sym)

# Try to load vendor-ed rhosync, otherwise load the gem
begin
  require 'vendor/rhosync/lib/rhosync'
rescue LoadError
  require 'rhosync'
end

$:.unshift File.join(File.dirname(__FILE__), "..") # FIXME:
# Load our rhosync application
require 'application'
include Rhosync

require 'rhosync/test_methods'

# Monkey patch to fix the following issue:
# /Library/Ruby/Gems/1.8/gems/rspec-core-2.5.1/lib/rspec/core/shared_example_group.rb:45:
# in `ensure_shared_example_group_name_not_taken': Shared example group '...' already exists (ArgumentError)
module RSpec
  module Core
    module SharedExampleGroup
    private
      def ensure_shared_example_group_name_not_taken(name)
      end
    end
  end
end

module TestHelpers
  class << self
    @created_records = {}
    attr_accessor :created_records
  end
end

shared_examples_for "SpecHelper" do
  include Rhosync::TestMethods
  
  def load_credentials(backend)
    file = YAML.load_file(File.join(ROOT_PATH,'..','rhocrm-test',"#{Rhosync.under_score(backend)}.yml"))
    return file.nil? ? {} : file
  end
  
  before(:all) do
    credentials = load_credentials(Application.backend)
    @test_user = "#{credentials[:test_user]}"
    @test_password = "#{credentials[:test_password]}"
    puts "Specify test user before running these specs" unless @test_user.length > 0
    puts "Specify test user password before running these specs" unless @test_password.length > 0
  end
  
  before(:each) do
    Store.db.flushdb
    Application.initializer(ROOT_PATH)
  end  
end
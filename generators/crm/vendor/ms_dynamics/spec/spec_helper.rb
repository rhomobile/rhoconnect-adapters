require 'rubygems'

# Set environment to test
ENV['RHO_ENV'] = 'test'
ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..'))

require 'bundler'
Bundler.require(:default, ENV['RHO_ENV'].to_sym)

# Try to load vendor-ed rhoconnect, otherwise load the gem
begin
  require 'vendor/rhoconnect/lib/rhoconnect'
rescue LoadError
  require 'rhoconnect'
end

$:.unshift File.join(File.dirname(__FILE__), "..") # FIXME:
# Load our rhoconnect application
require 'application'
include Rhoconnect

require 'rhoconnect/test_methods'

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
    
    @already_authenticated = false
    attr_accessor :already_authenticated
  end
end

shared_examples_for "SpecHelper" do
  include Rhoconnect::TestMethods
  
  def load_credentials(backend)
    file = YAML.load_file(File.join(ROOT_PATH,'..','rhocrm-test',"#{Rhoconnect.under_score(backend)}.yml"))
    return file.nil? ? {} : file
  end
  
  before(:all) do
    credentials = load_credentials(Application.backend)
    @test_user = "#{credentials[:test_user]}"
    @test_password = "#{credentials[:test_password]}"
    puts "Specify test user before running these specs" unless @test_user.length > 0
    puts "Specify test user password before running these specs" unless @test_password.length > 0
    unless TestHelpers.already_authenticated
      Store.db.flushdb
      if @test_user.length > 0 and @test_password.length > 0
        puts "Performing authentication with #{Application.backend} CRM instance for the user [#{@test_user}]"
        TestHelpers.already_authenticated = Application.authenticate(@test_user,@test_password) 
      end
    end
  end
    
  before(:each) do
    # preserving auth info 
    auth_info = Rhocrm::MsDynamics.load_auth_info(@test_user)
    Store.db.flushdb
    Application.initializer(ROOT_PATH)
    # restoring auth info in the DB
    Rhocrm::MsDynamics.save_auth_info(@test_user,auth_info) unless auth_info.nil?
  end
end
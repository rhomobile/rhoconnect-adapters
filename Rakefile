require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
       
TYPES = { 
  :gen   => 'spec/generator/*_spec.rb',
  :ms => 'spec/apps/ms_dynamics*_spec.rb',
  :salesforce => 'spec/apps/salesforce*_spec.rb',
#  not officially supported - can not be tested
#  :oracle => 'spec/apps/oracle_on_demand*_spec.rb',
#  :sugar => 'spec/apps/sugar*_spec.rb'
}

TYPES.each do |type,files|
  desc "Run specs in #{files}"
  RSpec::Core::RakeTask.new("spec:#{type}") do |t|
    t.rspec_opts = ["-b", "-c", "-fd"]
    t.pattern = FileList[TYPES[type]]
    t.rcov = false
  end
end

desc "Run all specs"
RSpec::Core::RakeTask.new("spec:all") do |t|
  t.rspec_opts = ["-b", "-c", "-fd"]
  t.pattern = FileList[TYPES.values]
  t.rcov = false
end

task :default => 'spec:all'

require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'rcov/rcovtask'
       
TYPES = { 
  :gen   => 'spec/generator/*_spec.rb',
  :oracle => 'spec/apps/oracle_on_demand*_spec.rb',
  :ms => 'spec/apps/ms_dynamics*_spec.rb',
  :sugar => 'spec/apps/sugar*_spec.rb'
}

TYPES.each do |type,files|
  desc "Run specs in #{files}"
  RSpec::Core::RakeTask.new("spec:#{type}") do |t|
    t.rspec_opts = ["-b", "-c", "-fd"]
    t.pattern = FileList[TYPES[type]]
  end
end

desc "Run all specs"
RSpec::Core::RakeTask.new("spec:all") do |t|
  t.rspec_opts = ["-b", "-c", "-fd"]
  t.pattern = FileList[TYPES.values]
end

task :default => 'spec:all'

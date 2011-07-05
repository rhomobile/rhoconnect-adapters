require 'rubygems'
require 'bundler'
require 'bundler/setup'
#Bundler.setup(:default, :test)
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'rcov/rcovtask'
       
TYPES = { 
#  :spec   => 'spec/**/*_spec.rb'
  :spec   => '/tmp/mynewapp/spec/**/*_spec.rb'
}

TYPES.each do |type,files|
  desc "Run specs in #{files}"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ["-b", "-c", "-fd"]
    t.pattern = FileList[TYPES[type]]
  end
end


#desc "Run all specs"
#RSpec::Core::RakeTask.new(:spec) do |t|
#  t.rspec_opts = ["-b", "-c", "-fd"]
#  t.pattern = 'spec/**/*_spec.rb'
#end

#desc "Run all specs with rcov"
#RSpec::Core::RakeTask.new(:rcov) do |t|
#  t.rcov = true
#  t.rspec_opts = ["-b", "-c", "-fd"]
#  t.rcov_opts =  ['--exclude', 'spec/*,gems/*']
#end

task :default => :spec

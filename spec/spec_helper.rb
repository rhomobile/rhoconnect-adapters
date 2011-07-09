#$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'rspec'
require 'templater/spec/helpers'

include Templater::Spec::Helpers
require 'rhocrm'
require File.join(File.dirname(__FILE__),'..','generators','rhocrm')


ENV['RACK_ENV'] = 'test'

# this method removes all vendor-specific actions
# from the generator, thus, cleaning up the templater
# in order to prepare it to run next batch
# of vendor-specific specs
def cleanup_templater(templater)
  standard_actions = {}
  templater.actions.each do |type,actions|
    standard_actions_array = []
    actions.each do |action|
      standard_actions_array << action unless action.name.to_s.index('vendor_custom') != nil
    end
    standard_actions[type] = standard_actions_array
  end
  templater.actions.clear
  standard_actions.each do |type,actions|
    templater.actions[type] = actions
  end
  templater
end

# in order to run the generator
# it is necessary to remove any previously loaded 
# vendor-specific actions and load the new ones
module Rhocrm
  class TestHelpers
    class << self
      def load_templater(backend)
        cleanup_templater(Rhocrm::AppGenerator)
        cleanup_templater(Rhocrm::SourceGenerator)
        Dir[File.join(File.dirname(__FILE__),'..','generators','vendor',"#{Rhosync.under_score(backend)}",'templates.rb')].each { |vendor_templates| load vendor_templates }
      end

      def generate_sample_app(destination_root,options,appname,backend)
        FileUtils.rm_rf "#{destination_root}/#{appname}"

        generator = Rhocrm::AppGenerator.new(destination_root,options,appname,backend)
        generator.invoke!
        generator.after_run
        generator
      end
    end
  end
end
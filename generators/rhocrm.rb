require 'rubygems'
require 'rhosync'
require 'templater'

module Rhocrm
  extend Templater::Manifold
  extend Rhocrm
  
  desc <<-DESC
    Rhocrm generator
  DESC
  
#  class SourceGenerator < BaseGenerator
#    def self.source_root
#      File.join(File.dirname(__FILE__), 'templates', 'source')
#    end

#    desc <<-DESC
#      Generates a new source adapter.
      
#      Required:
#        name        - source name(i.e. product)
#    DESC

#    first_argument :name, :required => true, :desc => "source name"

#    template :source do |template|
#      template.source = 'source_adapter.rb'
#      template.destination = "sources/#{underscore_name}.rb"
#      settings_file = File.join(@destination_root,'settings','settings.yml')
#      settings = YAML.load_file(settings_file)
#      settings[:sources] ||= {}
#      settings[:sources][class_name] = {:poll_interval => 300}
#      File.open(settings_file, 'w' ) do |file|
#        file.write "#Sources" + {:sources => settings[:sources]}.to_yaml[3..-1]
#        envs = {}
#        [:development,:test,:production].each do |env|
#          envs[env] = settings[env]
#        end
#        file.write envs.to_yaml[3..-1]
#      end
#    end
    
#    template :source_spec do |template|
#      template.source = 'source_spec.rb'
#      template.destination = "spec/sources/#{underscore_name}_spec.rb"
#    end
#  end
  
#  add :app, AppGenerator
  add :source, Rhosync::SourceGenerator
end
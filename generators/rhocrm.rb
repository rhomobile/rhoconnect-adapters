require 'rubygems'
require 'rhosync'

require File.join('rhosync', '..','..','generators','rhosync')
require 'templater'

module Rhocrm
  extend Templater::Manifold
  extend Rhocrm
  
  desc <<-DESC
    Rhocrm generator
  DESC
  
  class BaseGenerator < Templater::Generator
    def class_name
      name.gsub('-', '_').camel_case
    end
    
    def underscore_name
      Rhosync.under_score(name)
    end
    
    def underscore_crm
      Rhosync.under_score(crm)
    end
    
    def crm_name
      crm
    end

    def gem_version
      VERSION
    end 
  end
  
  class AppGenerator < Rhosync::AppGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates', 'application')
    end
    
    desc <<-DESC
      Generates a new rhosync application.
      
      Required:
        name        - application name
    DESC
    
    first_argument :name, :required => true, :desc => "application name"
    second_argument :crm, :required => true, :desc => "CRM backend"
    
    puts " we have here templates defined : " + templates.inspect
    
  end
    
    
    
  class SourceGenerator < BaseGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates', 'source')
    end

    desc <<-DESC
      Generates a new source adapter based on CRM object.
      
      Required:
        name        - source name(i.e. Account)
        CRM backend - name of the CRM backend
    DESC

    first_argument :name, :required => true, :desc => "source name"
    second_argument :crm, :required => true, :desc => "CRM backend name"

    template :source do |template|
      template.source = 'source_adapter.rb'
      template.destination = "sources/#{underscore_name}.rb"
      settings_file = File.join(@destination_root,'settings','settings.yml')
      settings = YAML.load_file(settings_file)
      settings[:sources] ||= {}
      settings[:sources][class_name] = {:poll_interval => 300}
      File.open(settings_file, 'w' ) do |file|
        file.write "#Sources" + {:sources => settings[:sources]}.to_yaml[3..-1]
        envs = {}
        [:development,:test,:production].each do |env|
          envs[env] = settings[env]
        end
        file.write envs.to_yaml[3..-1]
      end
    end
    
#    template :source_spec do |template|
#      template.source = 'source_spec.rb'
#      template.destination = "spec/sources/#{underscore_name}_spec.rb"
#    end
  end
  
  add :app, AppGenerator
  add :source, SourceGenerator
end
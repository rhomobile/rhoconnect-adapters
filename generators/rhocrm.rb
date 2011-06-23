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
  
  class AppGenerator < BaseGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates', 'application')
    end
    
    desc <<-DESC
      Generates a new rhosync application.
      
      Required:
        name        - application name
        CRM backend - name of the CRM backend
    DESC
    
    first_argument :name, :required => true, :desc => "application name"
    second_argument :crm, :required => true, :desc => "CRM backend"
    
    # purpose of this call is to invoke all templates in 
    # the Rhosync::Generator except the :application - which is overriden here
    # after app is generated , generate 4 standard sources
    invoke :rhosync_app do |rhosync_gen| 
      app_template = nil
      rhosync_gen.templates.each do |t|
        if t.name == :application
          app_template = t
          break
        end
      end
      rhosync_gen.templates.delete(app_template)
      rhosync_gen.new(destination_root, {}, name)
    end
    template :application do |template|
      template.source = 'application.rb'
      template.destination = "#{name}/application.rb"
    end
    
    def self.add_platform_templates(tname)
      template tname do |t|
         yield t,name,crm
      end
    end
    
    def after_run
      Rhocrm.run_cli(File.join(destination_root,name), 'rhocrm', Rhocrm::VERSION, ['source', 'account', crm])
    end
    
    # after app is generated , generate 4 standard sources
    #invoke :source do |source_gen|
    #  source_gen.new(File.join(destination_root,name),   {}, 'account', crm)
    #end
    #invoke :source do |source_gen|
    #  source_gen.new(destination_root, {}, 'contact', crm)
    #end
    #invoke :source do |source_gen|
    #  source_gen.new(destination_root, {}, 'lead', crm)
    #end
    #invoke :source do |source_gen|
    #  source_gen.new(destination_root, {}, 'opportunity', crm)
    #end
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
    
    def self.add_vendor_templates(tname)
      template tname do |t|
         yield t,name,crm
      end
    end
    
#    template :source_spec do |template|
#      template.source = 'source_spec.rb'
#      template.destination = "spec/sources/#{underscore_name}_spec.rb"
#    end
  end
  
  add :rhosync_app, Rhosync::AppGenerator
  add :app, AppGenerator
  add :source, SourceGenerator
end

Rhocrm::AppGenerator.add_vendor_templates :picklist_wsdl do |template,name,crm|
  template.source = File.join('..','platform','oracle_on_demand','wsdl','Picklist.wsdl')
  template.destination = File.join("#{name}", 'wsdl', 'Picklist.wsdl')
end

Rhocrm::SourceGenerator.add_vendor_templates :object_wsdl do |template,name,crm|
  class_name = name.gsub('-', '_').camel_case
  template.source = File.join('..','platform','oracle_on_demand','wsdl',"#{class_name}.wsdl")
  template.destination = File.join('wsdl', "#{class_name}.wsdl")
end
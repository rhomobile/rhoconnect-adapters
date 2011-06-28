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
    
    def configure_gemfile
      gem_file = File.join("#{name}",'Gemfile')
      doc = "\ngem 'rhocrm', '#{gem_version}'\n"
      File.open(gem_file, 'a') {|f| f.write(doc) }
    end
    
    def self.invoke_generator(gen_name, excludes = nil)
      invoke gen_name do |ext_gen| 
        if not excludes.nil?
          ext_gen.templates.delete_if {|t| excludes.index(t.name) != nil }
        end
        ext_gen.new(destination_root, {}, name)
      end
    end
    
    def self.add_vendor_templates(verb, tname, &block)
      send verb, tname do |t|
        yield t,name,crm
      end
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
    invoke_generator :rhosync_app, [:application]
    template :application do |template|
      template.source = 'application.rb'
      template.destination = "#{name}/application.rb"
    end
    template :vendor_application do |template|
      template.source = File.join('..','..','vendor',"#{underscore_crm}",'application.rb')
      template.destination = File.join("#{name}",'vendor',"#{underscore_crm}",'application.rb')
    end
    
    def after_run
      configure_gemfile
      # after app is generated , generate 4 standard sources
      Rhocrm.run_cli(File.join(destination_root,name), 'rhocrm', Rhocrm::VERSION, ['source', 'account', crm])
    end
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
    
    invoke_generator :rhosync_source, [:source]
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
    template :vendor_adapter do |template|
      template.source = File.join('..','..','vendor',"#{underscore_crm}",'adapter.rb')
      template.destination = File.join(@destination_root,'vendor',"#{underscore_crm}",'adapter.rb')
    end
  end
  
  add_private :rhosync_app, Rhosync::AppGenerator
  add_private :rhosync_source, Rhosync::SourceGenerator
  add :app, AppGenerator
  add :source, SourceGenerator
end

include Rhocrm
Dir[File.join(File.dirname(__FILE__),'vendor',"#{Rhosync.under_score(ARGV[2])}",'templates.rb')].each { |vendor_templates| load vendor_templates }

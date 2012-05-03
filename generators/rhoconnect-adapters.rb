require 'rubygems'
require 'rhoconnect'

require File.join('rhoconnect', '..','..','generators','rhoconnect')
require 'templater'

require 'rhoconnect-adapters'

module RhoconnectAdapters
  extend Templater::Manifold
  extend RhoconnectAdapters
  
  desc <<-DESC
    Rhoconnect-adapters generator
  DESC
  
  class NotSupportedBackendError < Templater::MalformattedArgumentError
  end
  
  class BaseGenerator < Templater::Generator
    def class_name
      name.gsub('-', '_').camel_case
    end
    
    def underscore_name
      Rhoconnect.under_score(name)
    end
    
    def configure_gemfile
      gem_file = File.join(@destination_root,"#{name}",'Gemfile')
      doc = "\ngem 'rhoconnect-adapters', '#{gem_version}'\n"
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
  end
    
  class CRMBaseGenerator < BaseGenerator
    def underscore_crm
      Rhoconnect.under_score(crm)
    end
    
    def crm_name
      crm
    end

    def gem_version
      VERSION
    end
    
    def self.check_valid_backend(name)
      if not RhoconnectAdapters::CRM.valid_backend?(name)
        puts "Requested CRM backend '#{name}' is not supported."
        puts ''
        puts 'List of supported backends:'
        RhoconnectAdapters::CRM.registered_backends.each do |crm|
          puts "    - #{crm}"
        end
        puts ''
        raise NotSupportedBackendError
      end
    end
    
    def configure_gemfile
      super
      
      # also call vendor-defined method
      gem_file = File.join(@destination_root,"#{name}",'Gemfile')
      vendor_module = RhoconnectAdapters::CRM.const_get(crm_name.to_sym)
      vendor_dependencies = vendor_module.configure_gemfile
      doc = ''
      vendor_dependencies.each do |key, val|
        doc += "gem '#{key}', '#{val}'\n"
      end
      
      File.open(gem_file, 'a') {|f| f.write(doc) }
    end
    
    def self.add_vendor_templates(verb, tname, &block)
      send verb, "#{tname}_vendor_custom".to_sym do |t|
        yield t,name,crm
      end
    end
    
    def initialize(generator_name, generator_class, *arguments)
      super(generator_name, generator_class, *arguments)
      RhoconnectAdapters::CRMBaseGenerator.check_valid_backend(arguments[1])
    end
  end
  
  class CRMAppGenerator < CRMBaseGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'crm', 'templates', 'application')
    end
    
    desc <<-DESC
      Generates a new rhoconnect CRM application.
      
      Required:
        name        - application name
        CRM backend - supported CRM backend #{RhoconnectAdapters::CRM.registered_backends.inspect}
    DESC
    
    first_argument :name, :required => true, :desc => "application name"
    second_argument :crm, :required => true, :desc => "supported CRM backend #{RhoconnectAdapters::CRM.registered_backends.inspect}"
    #third_argument :__bare, :required => false, :desc => "generate CRM application without standard sources", :as => :boolean
    option :bare, :default => false, :desc => "generate CRM application without standard sources", :as => :boolean
    
    # to prevent re-loading on subsequent loads
    actions.clear
    
    # purpose of this call is to invoke all templates in 
    # the Rhoconnect::Generator except the :application - which is overriden here
    invoke_generator :rhoconnect_app, [:application, :spec_helper]
    template :application do |template|
      template.source = 'application.rb'
      template.destination = "#{name}/application.rb"
    end
    template :spec_helper do |template|
      source_filename = File.join('..','..','vendor',underscore_crm,'spec','spec_helper.rb')
      if File.exists? File.join(CRMAppGenerator.source_root, source_filename)
        template.source = source_filename
      else
        template.source = File.join('..','spec','spec_helper.rb')
      end
      template.destination = "#{name}/spec/spec_helper.rb"
    end
    template :vendor_application do |template|
      template.source = File.join('..','..','vendor',"#{underscore_crm}",'application.rb')
      template.destination = File.join("#{name}",'vendor',"#{underscore_crm}",'application.rb')
    end
    template :vendor_adapter do |template|
      template.source = File.join('..','..','vendor',"#{underscore_crm}",'adapter.rb')
      template.destination = File.join("#{name}",'vendor',"#{underscore_crm}",'adapter.rb')
    end
    
    def after_run
      configure_gemfile
      # after app is generated , generate the standard sources
      # but only if --bare is not specified
      if not bare
        RhoconnectAdapters::CRM.standard_sources.each do |source|
          RhoconnectAdapters.run_cli(File.join(destination_root,name), 'rhoconnect-adapters', RhoconnectAdapters::VERSION, ['crmsource', "#{source}", crm])
        end
      end
      
      # after everything is done - run 'bundle install' for the first time
      install_gems_note = <<_BUNDLE_INSTALL_

In the future, to ensure that all the dependencies in your rhoconnect application 
are available execute these commands:
      cd #{name} && bundle install

If you're setting up the application in a production environment run the following:
      cd #{name} && bundle install --without=test development

_BUNDLE_INSTALL_

      running_bundler_first_time = <<_RUN_BUNDLER

Executing 'bundle install' for the first time in your freshly baked application!
      cd #{destination_root}/#{name} && bundle install

_RUN_BUNDLER

      puts running_bundler_first_time
      system("cd #{destination_root}/#{name} && bundle install")
      puts install_gems_note
    end
  end
     
  class CRMSourceGenerator < CRMBaseGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'crm', 'templates', 'source')
    end

    desc <<-DESC
      Generates a new source adapter based on CRM object.
      
      Required:
        name        - source name(i.e. Account)
        CRM backend - supported CRM backend #{RhoconnectAdapters::CRM.registered_backends.inspect}
    DESC

    first_argument :name, :required => true, :desc => "source name"
    second_argument :crm, :required => true, :desc => "supported CRM backend #{RhoconnectAdapters::CRM.registered_backends.inspect}"
    
    # to prevent re-loading on subsequent loads
    actions.clear
    
    invoke_generator :rhoconnect_source, [:source, :source_spec]
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
        # write all other settings
        [:development, :test, :production, :sources].each do |key|
          settings.delete(key)
        end
        file.write settings.to_yaml[3..-1] unless settings.empty?
      end
    end
    template :source_spec do |template|
      source_filename = File.join('..','..','vendor',underscore_crm,'spec','sources',"#{underscore_name}_spec.rb")
      if File.exists? File.join(CRMSourceGenerator.source_root, source_filename)
        template.source = source_filename
      else
        template.source = 'source_spec.rb'
      end
      template.destination = "spec/sources/#{underscore_name}_spec.rb"
    end
  end
  
  add_private :rhoconnect_app, Rhoconnect::AppGenerator
  add_private :rhoconnect_source, Rhoconnect::SourceGenerator
  add :crmapp, CRMAppGenerator
  add :crmsource, CRMSourceGenerator
end

include RhoconnectAdapters

if ARGV[0] == 'crmapp' || ARGV[0] == 'crmsource'
  backend_arg = ARGV.last 
  if backend_arg == '--bare'
    backend_arg = ARGV[2]
  end
  Dir[File.join(File.dirname(__FILE__),'crm','vendor',"#{Rhoconnect.under_score(backend_arg)}",'templates.rb')].each { |vendor_templates| load vendor_templates }
end

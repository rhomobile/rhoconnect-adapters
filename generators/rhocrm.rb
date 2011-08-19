require 'rubygems'
require 'rhosync'

require File.join('rhosync', '..','..','generators','rhosync')
require 'templater'

require 'rhocrm'

module Rhocrm
  extend Templater::Manifold
  extend Rhocrm
  
  class NotSupportedBackendError < Templater::MalformattedArgumentError
  end
  
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
      gem_file = File.join(@destination_root,"#{name}",'Gemfile')
      doc = "\ngem 'rhocrm', '#{gem_version}'\n"
      
      # also call vendor-defined method
      vendor_module = Rhocrm.const_get(crm_name.to_sym)
      vendor_dependencies = vendor_module.configure_gemfile
      vendor_dependencies.each do |key, val|
        doc += "gem '#{key}', '#{val}'\n"
      end
      File.open(gem_file, 'a') {|f| f.write(doc) }
    end
    
    def self.check_valid_backend(name)
      if not Rhocrm.valid_backend?(name)
        puts "Requested CRM backend '#{name}' is not supported."
        puts ''
        puts 'List of supported backends:'
        Rhocrm.registered_backends.each do |crm|
          puts "    - #{crm}"
        end
        puts ''
        raise NotSupportedBackendError
      end
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
      send verb, "#{tname}_vendor_custom".to_sym do |t|
        yield t,name,crm
      end
    end
    
    def initialize(generator_name, generator_class, *arguments)
      super(generator_name, generator_class, *arguments)
      Rhocrm::BaseGenerator.check_valid_backend(arguments[1])
    end
  end
  
  class AppGenerator < BaseGenerator
    def self.source_root
      File.join(File.dirname(__FILE__), 'templates', 'application')
    end
    
    desc <<-DESC
      Generates a new rhosync CRM application.
      
      Required:
        name        - application name
        CRM backend - supported CRM backend #{Rhocrm.registered_backends.inspect}
    DESC
    
    first_argument :name, :required => true, :desc => "application name"
    second_argument :crm, :required => true, :desc => "supported CRM backend #{Rhocrm.registered_backends.inspect}"
    #third_argument :__bare, :required => false, :desc => "generate CRM application without standard sources", :as => :boolean
    option :bare, :default => false, :desc => "generate CRM application without standard sources", :as => :boolean
    
    # to prevent re-loading on subsequent loads
    actions.clear
    
    # purpose of this call is to invoke all templates in 
    # the Rhosync::Generator except the :application - which is overriden here
    invoke_generator :rhosync_app, [:application, :spec_helper]
    template :application do |template|
      template.source = 'application.rb'
      template.destination = "#{name}/application.rb"
    end
    template :spec_helper do |template|
      source_filename = File.join('..','..','vendor',underscore_crm,'spec','spec_helper.rb')
      if File.exists? File.join(AppGenerator.source_root, source_filename)
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
        Rhocrm.standard_sources.each do |source|
          Rhocrm.run_cli(File.join(destination_root,name), 'rhocrm', Rhocrm::VERSION, ['source', "#{source}", crm])
        end
      end
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
        CRM backend - supported CRM backend #{Rhocrm.registered_backends.inspect}
    DESC

    first_argument :name, :required => true, :desc => "source name"
    second_argument :crm, :required => true, :desc => "supported CRM backend #{Rhocrm.registered_backends.inspect}"
    
    # to prevent re-loading on subsequent loads
    actions.clear
    
    invoke_generator :rhosync_source, [:source, :source_spec]
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
    template :source_spec do |template|
      source_filename = File.join('..','..','vendor',underscore_crm,'spec','sources',"#{underscore_name}_spec.rb")
      if File.exists? File.join(SourceGenerator.source_root, source_filename)
        template.source = source_filename
      else
        template.source = 'source_spec.rb'
      end
      template.destination = "spec/sources/#{underscore_name}_spec.rb"
    end
  end
  
  add_private :rhosync_app, Rhosync::AppGenerator
  add_private :rhosync_source, Rhosync::SourceGenerator
  add :app, AppGenerator
  add :source, SourceGenerator
end

include Rhocrm
backend_arg = ARGV.last 
if backend_arg == '--bare'
  backend_arg = ARGV[2]
end
Dir[File.join(File.dirname(__FILE__),'vendor',"#{Rhosync.under_score(backend_arg)}",'templates.rb')].each { |vendor_templates| load vendor_templates }

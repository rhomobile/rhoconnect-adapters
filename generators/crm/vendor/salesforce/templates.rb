# these are Sugar-specific Templater::Generator templates
module RhoconnectAdapters
  module CRM
    module Salesforce
      class << self
        def configure_gemfile
          {}
        end
      end
    end
  end
end

RhoconnectAdapters::CRMAppGenerator.add_vendor_templates :file, :settings_yml do |file,name,crm|
  file.source = File.join('..','..','vendor','salesforce','settings','settings.yml')
  file.destination = File.join("#{name}", 'vendor','salesforce','settings','settings.yml')
end

RhoconnectAdapters::CRMAppGenerator.add_vendor_templates :file, :application_spec do |file,name,crm|
  file.source = File.join('..','..','vendor','salesforce','spec','application_spec.rb')
  file.destination = File.join("#{name}", 'spec','application_spec.rb')
end

RhoconnectAdapters::CRMSourceGenerator.add_vendor_templates :file, :object_yml do |file,name,crm|
  source_name = name.gsub('-', '_').camel_case
  source_filename = File.join('..','..','vendor','salesforce','settings',"#{source_name}.yml")
  if File.exists? File.join(CRMSourceGenerator.source_root, source_filename)
    file.source = source_filename
  else
    file.source = File.join('..','..','vendor','salesforce','settings',"GenericObject.yml")
  end
  file.destination = File.join('vendor','salesforce','settings', "#{source_name}.yml")
end

RhoconnectAdapters::CRMSourceGenerator.add_vendor_templates :template, :spec_data do |template,name,crm|
  source_name = name.gsub('-', '_').camel_case
  source_filename = File.join('..','..','vendor','salesforce','spec_data',"#{source_name}.yml")
  if File.exists? File.join(CRMSourceGenerator.source_root, source_filename)
    template.source = source_filename
  else
    template.source = File.join('..','..','vendor','salesforce','spec_data',"GenericObject.yml")
  end
  template.destination = File.join('vendor','salesforce','spec_data', "#{source_name}.yml")
end


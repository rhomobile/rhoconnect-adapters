# these are MsDynamics-specific Templater::Generator templates
module RhoconnectAdapters
  module CRM
    module MsDynamics
      class << self
        def configure_gemfile
          # put all specific dependencies here
          # in the form of hash {'gem' => 'version'}
          {}
        end
      end
    end
  end
end

RhoconnectAdapters::CRMAppGenerator.add_vendor_templates :directory, :msdynamics_lib_files do |dir,name,crm|
  dir.source = File.join('..','..','vendor','ms_dynamics','lib')
  dir.destination = File.join("#{name}", 'vendor','ms_dynamics','lib')
end

RhoconnectAdapters::CRMAppGenerator.add_vendor_templates :file, :ms_dynamics_main_require do |file,name,crm|
  file.source = File.join('..','..','vendor','ms_dynamics','ms_dynamics.rb')
  file.destination = File.join("#{name}", 'vendor','ms_dynamics','ms_dynamics.rb')
end

RhoconnectAdapters::CRMAppGenerator.add_vendor_templates :file, :settings_yml do |file,name,crm|
  file.source = File.join('..','..','vendor','ms_dynamics','settings','settings.yml')
  file.destination = File.join("#{name}", 'vendor','ms_dynamics','settings','settings.yml')
end

RhoconnectAdapters::CRMAppGenerator.add_vendor_templates :file, :application_spec do |file,name,crm|
  file.source = File.join('..','..','vendor','ms_dynamics','spec','application_spec.rb')
  file.destination = File.join("#{name}", 'spec','application_spec.rb')
end

RhoconnectAdapters::CRMSourceGenerator.add_vendor_templates :file, :object_yml do |file,name,crm|
  source_name = name.gsub('-', '_').camel_case
  source_filename = File.join('..','..','vendor','ms_dynamics','settings',"#{source_name}.yml")
  if File.exists? File.join(CRMSourceGenerator.source_root, source_filename)
    file.source = source_filename
  else
    file.source = File.join('..','..','vendor','ms_dynamics','settings',"GenericObject.yml")
  end
  file.destination = File.join('vendor','ms_dynamics','settings', "#{source_name}.yml")
end

RhoconnectAdapters::CRMSourceGenerator.add_vendor_templates :template, :spec_data do |template,name,crm|
  source_name = name.gsub('-', '_').camel_case
  source_filename = File.join('..','..','vendor','ms_dynamics','spec_data',"#{source_name}.yml")
  if File.exists? File.join(CRMSourceGenerator.source_root, source_filename)
    template.source = source_filename
  else
    template.source = File.join('..','..','vendor','ms_dynamics','spec_data',"GenericObject.yml")
  end
  template.destination = File.join('vendor','ms_dynamics','spec_data', "#{source_name}.yml")
end


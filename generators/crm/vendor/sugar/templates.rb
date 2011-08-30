# these are Sugar-specific Templater::Generator templates
module Rhocrm
  extend Rhocrm
  module Sugar
    class << self
      def configure_gemfile
        # put all specific dependencies here
        # in the form of hash {'gem' => 'version'}
        { 'activesupport' => '>= 3.0.9',
          'i18n' => '>= 0.6.0',
          'sugarcrm' => '>= 0.9.15'
        }
      end
    end
  end
end

Rhocrm::AppGenerator.add_vendor_templates :file, :sugar_main_require do |file,name,crm|
  file.source = File.join('..','..','vendor','sugar','sugar.rb')
  file.destination = File.join("#{name}", 'vendor','sugar','sugar.rb')
end

Rhocrm::AppGenerator.add_vendor_templates :file, :settings_yml do |file,name,crm|
  file.source = File.join('..','..','vendor','sugar','settings','settings.yml')
  file.destination = File.join("#{name}", 'vendor','sugar','settings','settings.yml')
end

Rhocrm::AppGenerator.add_vendor_templates :file, :application_spec do |file,name,crm|
  file.source = File.join('..','..','vendor','sugar','spec','application_spec.rb')
  file.destination = File.join("#{name}", 'spec','application_spec.rb')
end

Rhocrm::SourceGenerator.add_vendor_templates :file, :object_yml do |file,name,crm|
  source_name = name.gsub('-', '_').camel_case
  source_filename = File.join('..','..','vendor','sugar','settings',"#{source_name}.yml")
  if File.exists? File.join(SourceGenerator.source_root, source_filename)
    file.source = source_filename
  else
    file.source = File.join('..','..','vendor','sugar','settings',"GenericObject.yml")
  end
  file.destination = File.join('vendor','sugar','settings', "#{source_name}.yml")
end

Rhocrm::SourceGenerator.add_vendor_templates :template, :spec_data do |template,name,crm|
  source_name = name.gsub('-', '_').camel_case
  source_filename = File.join('..','..','vendor','sugar','spec_data',"#{source_name}.yml")
  if File.exists? File.join(SourceGenerator.source_root, source_filename)
    template.source = source_filename
  else
    template.source = File.join('..','..','vendor','sugar','spec_data',"GenericObject.yml")
  end
  template.destination = File.join('vendor','sugar','spec_data', "#{source_name}.yml")
end





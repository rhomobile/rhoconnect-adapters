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



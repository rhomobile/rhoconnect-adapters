# these are Sugar-specific Templater::Generator templates
Rhocrm::AppGenerator.add_vendor_templates :file, :sugar_main_require do |file,name,crm|
  file.source = File.join('..','..','vendor','sugar','sugar.rb')
  file.destination = File.join("#{name}", 'vendor','sugar','sugar.rb')
end

Rhocrm::AppGenerator.add_vendor_templates :file, :settings_yml do |file,name,crm|
  file.source = File.join('..','..','vendor','sugar','settings','settings.yml')
  file.destination = File.join("#{name}", 'vendor','sugar','settings','settings.yml')
end

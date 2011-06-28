# these are Oracle-specific Templater::Generator templates
Rhocrm::AppGenerator.add_vendor_templates :template, :settings_yml do |template,name,crm|
  template.source = File.join('..','..','vendor','oracle_on_demand','settings','settings.yml')
  template.destination = File.join("#{name}", 'vendor','oracle_on_demand','settings','settings.yml')
end

Rhocrm::SourceGenerator.add_vendor_templates :file, :object_yml do |file,name,crm|
  class_name = name.gsub('-', '_').camel_case
  file.source = File.join('..','..','vendor','oracle_on_demand','settings',"#{class_name}.yml")
  file.destination = File.join('vendor','oracle_on_demand','settings', "#{class_name}.yml")
end



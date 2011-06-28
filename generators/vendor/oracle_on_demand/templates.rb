# these are Oracle-specific Templater::Generator templates
Rhocrm::AppGenerator.add_vendor_templates :template, :settings_yml do |template,name,crm|
  template.source = File.join('..','..','vendor','oracle_on_demand','settings','settings.yml')
  template.destination = File.join("#{name}", 'vendor','oracle_on_demand','settings','settings.yml')
end

Rhocrm::SourceGenerator.add_vendor_templates :file, :object_yml do |file,name,crm|
  source_name = name.gsub('-', '_').camel_case
  source_filename = File.join('..','..','vendor','oracle_on_demand','settings',"#{source_name}.yml")
  if File.exists? File.join(File.dirname(__FILE__), source_filename)
    file.source = source_filename
  else
    file.source = File.join('..','..','vendor','oracle_on_demand','settings',"GenericObject.yml")
  end
  file.destination = File.join('vendor','oracle_on_demand','settings', "#{source_name}.yml")
end






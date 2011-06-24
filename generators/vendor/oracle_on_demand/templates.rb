# these are Oracle-specific Templater::Generator templates
Rhocrm::AppGenerator.add_vendor_templates :picklist_wsdl do |template,name,crm|
  template.source = File.join('..','..','vendor','oracle_on_demand','wsdl','Picklist.wsdl')
  template.destination = File.join("#{name}", 'vendor','oracle_on_demand','wsdl', 'Picklist.wsdl')
end

Rhocrm::SourceGenerator.add_vendor_templates :object_wsdl do |template,name,crm|
  class_name = name.gsub('-', '_').camel_case
  template.source = File.join('..','..','vendor','oracle_on_demand','wsdl',"#{class_name}.wsdl")
  template.destination = File.join('vendor','oracle_on_demand','wsdl', "#{class_name}.wsdl")
end

Rhocrm::SourceGenerator.add_vendor_templates :object_yml do |template,name,crm|
  class_name = name.gsub('-', '_').camel_case
  template.source = File.join('..','..','vendor','oracle_on_demand','settings',"#{class_name}.yml")
  template.destination = File.join('vendor','oracle_on_demand','settings', "#{class_name}.yml")
end

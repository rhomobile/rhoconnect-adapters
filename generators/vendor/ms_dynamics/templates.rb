# these are Oracle-specific Templater::Generator templates
Rhocrm::AppGenerator.add_vendor_templates :directory, :msdynamics_lib do |dir,name,crm|
  dir.source = File.join('..','..','vendor','ms_dynamics','lib')
  dir.destination = File.join("#{name}", 'vendor','ms_dynamics')
end

Rhocrm::AppGenerator.add_vendor_templates :file, :application_spec do |file,name,crm|
  file.source = File.join('..','..','vendor','oracle_on_demand','spec','application_spec.rb')
  file.destination = File.join("#{name}", 'spec','application_spec.rb')
end


# these are MsDynamics-specific Templater::Generator templates
Rhocrm::AppGenerator.add_vendor_templates :directory, :msdynamics_lib_files do |dir,name,crm|
  dir.source = File.join('..','..','vendor','ms_dynamics','lib')
  dir.destination = File.join("#{name}", 'vendor','ms_dynamics','lib')
end

Rhocrm::AppGenerator.add_vendor_templates :file, :ms_dynamics_main_require do |file,name,crm|
  file.source = File.join('..','..','vendor','ms_dynamics','ms_dynamics.rb')
  file.destination = File.join("#{name}", 'vendor','ms_dynamics','ms_dynamics.rb')
end

Rhocrm::AppGenerator.add_vendor_templates :file, :settings_yml do |file,name,crm|
  file.source = File.join('..','..','vendor','ms_dynamics','settings','settings.yml')
  file.destination = File.join("#{name}", 'vendor','ms_dynamics','settings','settings.yml')
end

Rhocrm::AppGenerator.add_vendor_templates :file, :application_spec do |file,name,crm|
  file.source = File.join('..','..','vendor','ms_dynamics','spec','application_spec.rb')
  file.destination = File.join("#{name}", 'spec','application_spec.rb')
end


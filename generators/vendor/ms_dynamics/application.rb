require 'rhocrm'
require 'vendor/ms_dynamics/ms_dynamics'

module Rhocrm
  module MsDynamics
    class Application < Rhosync::Base
      class << self
        def authenticate(username,password,session)
          begin
            # TODO: handle exceptions
            # From time to time Win Live doesn't respond or returns 400 (Bad Request); 
            # we probably should retry in such cases  
            wlid_ticket, wlid_expires = 
              Rhocrm::MsDynamics::WlidService.get_ticket(username,password)
            crm_service_url, crm_metadata_service_url, crm_ticket, crm_ticket_expires, user_organization = 
              Rhocrm::MsDynamics::DiscoveryService.get_crm_ticket(get_settings[:msdynamics_ticket_url],wlid_ticket)
            # store recieved tickets and associated information in redis for the future reference  
            Rhocrm::MsDynamics.save_auth_info(username,
              {
                "wlid_ticket" => wlid_ticket,
                "wlid_expires" => wlid_expires.to_s,
                "crm_service_url" => crm_service_url,
                "crm_metadata_service_url" => crm_metadata_service_url,
                "crm_ticket" => crm_ticket,
                "crm_ticket_expires" => crm_ticket_expires.to_s,
                "user_organization" => user_organization
              })
          rescue Exception => ex
            warn "Can't authenticate user #{username}: " + ex.inspect
            return false
          end
          true
        end
        
        def get_settings
          return @settings if @settings
          begin
            file = YAML.load_file(File.join(ROOT_PATH,'settings','settings.yml'))
            env = (ENV['RHO_ENV'] || :development).to_sym
            @settings = file[env]
            
            # vendor-specific settings
            file = YAML.load_file(File.join(ROOT_PATH,'vendor','ms_dynamics','settings','settings.yml'))
            @settings.merge!(file[env])
          rescue Exception => e
            puts "Error opening settings file: #{e}"
            puts e.backtrace.join("\n")
            raise e
          end
        end
      end
    end
  end
end

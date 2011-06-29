require 'rhocrm'
require 'rhocrm/ms_dynamics'

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
              MSDynamics::WlidService.get_ticket(username,password)
            crm_service_url, crm_ticket, crm_ticket_expires, user_organization = 
              MSDynamics::DiscoveryService.get_crm_ticket("rhomobileinc.crm.dynamics.com",wlid_ticket)
            # store recieved tickets and associated information in redis for the future reference  
            Store.set_data("#{username}-msdynamics-auth-info","#{username}" => {
              "wlid_ticket" => wlid_ticket,
              "wlid_expires" => wlid_expires.to_s,
              "crm_service_url" => crm_service_url,
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
      end
    end
  end
end

Application.initializer(ROOT_PATH)
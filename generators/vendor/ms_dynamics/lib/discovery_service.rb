module Rhocrm
  module MsDynamics
    class DiscoveryService < SoapService

      # Get the Crm Service Url, Crm Ticket, Crm Ticket expiration date/time, and Unique User Organization Name 
      def self.get_crm_ticket(host_name,wlid_ticket)
        @wlid_ticket = wlid_ticket
        @discovery_service_url = "https://#{host_name}/MSCRMServices/2007/Passport/CrmDiscoveryService.asmx"
        retrieve_ticket(get_user_organization)   
      end  
  
      private
      class << self
        def execute_discovery_request(request,params='')
          body = "
            <Execute xmlns=\"http://schemas.microsoft.com/crm/2007/CrmDiscoveryService\">
              <Request xsi:type=\"#{request}\">
                #{params}
                <PassportTicket>#{@wlid_ticket}</PassportTicket>
              </Request>
            </Execute>"
          send_request(@discovery_service_url,compose_message(nil,body),
            "http://schemas.microsoft.com/crm/2007/CrmDiscoveryService/Execute")
        end  

        # Retrieve a list of organizations that the logged on user is a member of
        # and select unique name of the first one
        # TODO: do we need to handle case when user is member of more then one org?
        def get_user_organization
          doc = execute_discovery_request('RetrieveOrganizationsRequest')
          select_node_text(doc,'//cds:OrganizationName[1]')
        end  
    
        # Retrieve the Crm Service Url, Crm Ticket, Crm Ticket expiration date/time, and Unique User Organization Name 
        def retrieve_ticket(user_organization)
          doc = execute_discovery_request('RetrieveCrmTicketRequest',"<OrganizationName>#{user_organization}</OrganizationName>")
          crm_ticket = select_node_text(doc,'//cds:CrmTicket')
          crm_ticket_expires = DateTime.parse(select_node_text(doc,'//cds:ExpirationDate'))
          crm_service_url = select_node_text(doc,'//cds:CrmServiceUrl')
          [crm_service_url, crm_ticket, crm_ticket_expires, user_organization]
        end
    
      end
  
    end
  end
end  
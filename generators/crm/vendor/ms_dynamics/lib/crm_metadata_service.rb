module Rhocrm
  module MsDynamics
    class CrmMetadataService < SoapService
      def initialize(crm_metadata_service_url,crm_ticket,user_organization)
        @crm_metadata_service_url = crm_metadata_service_url
        @message_header  = "
        <CrmAuthenticationToken xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
          <AuthenticationType xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">1</AuthenticationType>
          <CrmTicket xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{crm_ticket}</CrmTicket>
          <OrganizationName xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{user_organization}</OrganizationName>
          <CallerId xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">00000000-0000-0000-0000-000000000000</CallerId>
        </CrmAuthenticationToken>"  
      end
    
      def request_picklist(entity_name,attribute)
        message = SoapService.compose_message(@message_header,
          "<Execute xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
            <Request xsi:type=\"RetrieveAttributeRequest\">
             <EntityLogicalName>#{entity_name}</EntityLogicalName>
             <LogicalName>#{attribute}</LogicalName>
             <RetrieveAsIfPublished>1</RetrieveAsIfPublished>
            </Request>
           </Execute>")
        doc = SoapService.send_request(@crm_metadata_service_url,message,get_action('Execute'))
        result = {}
        options = SoapService.select_node(doc, '//cws7:Option')
        options.each do |option|
          value = SoapService.select_node_text(option, 'cws7:Value')
          result[value] = SoapService.select_node_text(option, 'cws7:Label/cws7:LocLabels/cws7:LocLabel/cws7:Label')
        end
        result
      end
      
      private
      def get_action(name)
        "http://schemas.microsoft.com/crm/2007/WebServices/#{name}"
      end
    end
  end
end



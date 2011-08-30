module Rhocrm
  module MsDynamics
    class CrmService < SoapService
      def initialize(crm_service_url,crm_ticket,user_organization)
        @crm_service_url = crm_service_url
        @message_header  = "
        <CrmAuthenticationToken xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
          <AuthenticationType xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">1</AuthenticationType>
          <CrmTicket xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{crm_ticket}</CrmTicket>
          <OrganizationName xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{user_organization}</OrganizationName>
          <CallerId xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">00000000-0000-0000-0000-000000000000</CallerId>
        </CrmAuthenticationToken>"  
      end
    
      def request(request_name)
        message = SoapService.compose_message(@message_header,
          "<Execute xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
             <Request xsi:type=\"#{request_name}\"/>
           </Execute>")
        SoapService.send_request(@crm_service_url,message,get_action('Execute'))
      end
    
      def retrieve(entity_name,entity_id,attributes)
        message = SoapService.compose_message(@message_header,
          "<Retrieve xmlns='http://schemas.microsoft.com/crm/2007/WebServices'>
            <entityName>#{entity_name}</entityName>
            <id>#{entity_id}</id>
            <columnSet xmlns:q1='http://schemas.microsoft.com/crm/2006/Query' xsi:type='q1:ColumnSet'>
              <q1:Attributes> 
                #{get_columns(attributes)} 
              </q1:Attributes> 
            </columnSet> 
          </Retrieve>")
        doc = SoapService.send_request(@crm_service_url,message,get_action('Retrieve'))
        res = {}
        attributes.each do |attribute|
          res.merge!(attribute => SoapService.select_node_text(doc,"//cws7:#{attribute}"))
        end
        res
      end
        
      def retrieve_multiple(entity_name, attributes, field_picklists_map, distinct=true, criteria_xml="")
        message = SoapService.compose_message(@message_header,
          "<RetrieveMultiple xmlns='http://schemas.microsoft.com/crm/2007/WebServices'>
            <query xmlns:q1='http://schemas.microsoft.com/crm/2006/Query' xsi:type='q1:QueryExpression'>
              <q1:EntityName>#{entity_name}</q1:EntityName>
              <q1:ColumnSet xsi:type='q1:ColumnSet'>
                <q1:Attributes>
                  #{get_columns(attributes)} 
                </q1:Attributes>
              </q1:ColumnSet>
              <q1:Distinct>#{distinct.to_s}</q1:Distinct>
              #{criteria_xml}
            </query>
          </RetrieveMultiple>")      
        doc = SoapService.send_request(@crm_service_url,message,get_action('RetrieveMultiple'))
        business_entities = SoapService.select_node(doc,'//cws6:BusinessEntity')
        result = {}
        business_entities.each do |business_entity|
          record = {}
          business_entity.children.each do |field|
            type_field = field.attributes['type']
            record.merge!("#{field.name}_attrtype" => type_field) unless type_field.nil?
            field_value = field.text
            # convert IntegerValues for Picklist types into User-friendly strings
            field_value = field_picklists_map[field.name][field.text] unless field_picklists_map[field.name].nil?
            record.merge!(field.name => field_value)
          end
          clean_attributes(entity_name,record)
          field_id = record["#{entity_name}id"]
          result[field_id] = record unless field_id.nil?
        end
        result
      end 
    
      def create(entity_name,params,types={})
        message = SoapService.compose_message(@message_header,
          "<Create xmlns='http://schemas.microsoft.com/crm/2007/WebServices'> 
            <entity xsi:type='#{entity_name}'>
              #{get_params(params,types)} 
            </entity> 
          </Create>") 
        doc = SoapService.send_request(@crm_service_url,message,get_action('Create'))
        SoapService.select_node_text(doc,'//cws7:CreateResult')        
      end
    
      def update(entity_name,entity_id,params,types={})
        message = SoapService.compose_message(@message_header,
          "<Update xmlns='http://schemas.microsoft.com/crm/2007/WebServices'>
            <entity xsi:type='#{entity_name}'>
              #{get_params(params,types)}
              <#{entity_name}id>#{entity_id}</#{entity_name}id> 
            </entity> 
          </Update>")
        SoapService.send_request(@crm_service_url,message,get_action('Update'))
      end
      
      def delete(entity_name,entity_id)
        message = SoapService.compose_message(@message_header,
          "<Delete xmlns='http://schemas.microsoft.com/crm/2007/WebServices'> 
            <entityName>#{entity_name}</entityName> 
            <id>#{entity_id}</id> 
           </Delete>") 
         SoapService.send_request(@crm_service_url,message,get_action('Delete'))
      end
    
      def get_current_user
        doc = request('WhoAmIRequest')
        SoapService.select_node_text(doc,'//cws7:UserId')
      end
        
      private
      def get_action(name)
        "http://schemas.microsoft.com/crm/2007/WebServices/#{name}"
      end
    
      def get_columns(attributes)
        columns = attributes.collect { |attrib| "<q1:Attribute>#{attrib}</q1:Attribute>" }
        columns.to_s
      end
    
      def get_params(params, types = {})
        res = []
        params.each do |name, value|
          type_attr = " type='#{types[name].to_s}'" unless types[name].nil?
          res << "<#{name}#{type_attr}>#{value}</#{name}>"
        end
        res.to_s
      end
    
      def clean_attributes(entity_name,attributes)
        name = "#{entity_name}id"
        id = attributes[name]
        attributes[name] = id[1..-2] if id
        attributes
      end
    end
  end
end

require 'rest-client'
require 'nokogiri'

module Rhocrm
  class SoapService
    @node_namespaces = {
        'wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
        'wsse'=> 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
    };
    @envelope_namespaces = <<-DESC
       xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" 
       xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" 
       xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"
       xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"
    DESC

    class << self
      # use node_namespaces attribute to specify namespaces used 
      # by SoapService's select_node and select_node_text methods 
      attr_accessor :node_namespaces
      # use envelope namespaces to be passed with the SOAP request
      attr_accessor :envelope_namespaces
         
      def select_node(doc,node_name)
        doc.xpath("#{node_name}",SoapService.node_namespaces)
      end

      def select_node_text(doc,node_name)
        doc.xpath("#{node_name}/text()",SoapService.node_namespaces).to_s.strip
      end

      def compose_wsse_header(username,password)
        "<wsse:Security>
          <wsse:UsernameToken wsu:Id=\"UsernameToken-1\">
            <wsse:Username>#{username}</wsse:Username>
            <wsse:Password Type=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText\">#{password}</wsse:Password>
          </wsse:UsernameToken>
        </wsse:Security>"
      end

      def compose_message(header,body,namespaces=Rhocrm::SoapService.envelope_namespaces)
        hdr = header ? "<s:Header>#{header}</s:Header>" : ""
        bdy = body ? "<s:Body>#{body}</s:Body>" : ""
        "<?xml version=\"1.0\"?>
         <s:Envelope #{namespaces}>
           #{hdr}
           #{bdy}
         </s:Envelope>"        
      end
      
      def send_request(endpoint,message,action=nil,content_type='text/xml; charset=UTF-8',cookie=nil)
        response = send_request_raw(endpoint, message, action, content_type, cookie)
        Nokogiri::XML(response)
      end
      
      def send_request_raw(endpoint,message,action=nil,content_type='text/xml; charset=UTF-8',cookie=nil)
        begin
          headers = { :content_type => content_type }
          headers.merge!({ "SOAPAction" => action }) if action
          headers.merge!({ "Cookie" => cookie }) if cookie
          response = RestClient.post(endpoint, message, headers)
        rescue RestClient::Exception => ex
          warn "#{self.name} error: " + ex.inspect.strip
          ex.backtrace.each { |line| warn 'from ' + line } 
          raise ex
        end
      end
    end    
  end
end
module Rhocrm
  module MsDynamics
    class WlidService < SoapService
      def self.get_ticket(user_name,password)
        # device client ID
        client_id = UUIDTools::UUID.random_create
        # random device name
        device_name = rand(10000).to_s+'12345678901234567890'
        # random device password
        device_password = 'random-device-password'
        # authentication policy
        policy = "MBI_SSL"
        # open information about CRM Online
        partner = "crm.dynamics.com";
        # Get authorization endpoint  
        authorization_endpoint = self._get_authorization_endpoint
        # Do the following once per machine.  
        # Register each machine that you need to authenticate with.
        self._register_machine(device_name,device_password,client_id)
        # Get device token based for the registered machine
        device_token = self._get_device_token(authorization_endpoint,device_name,device_password)
        # Get WLID Ticket for the user
        self._get_ticket(authorization_endpoint,user_name,password,partner,policy,client_id,device_token)
      end
  
      private
      class << self
        def _get_authorization_endpoint
          xml = RestClient.get("https://nexus.passport.com/federationmetadata/2006-12/FederationMetaData.xml")
          federation_metadata = Nokogiri::XML(xml)
          federation_metadata.xpath("//fed:FederationMetadata/fed:Federation/fed:TargetServiceEndpoint/wsa:Address").text.strip
        end

        # Registers a machine/device with the device registration Windows Live ID service. 
        # Device registration is required only once per computer or device.
        # The result of this request will contain the PUID (Device ID) of the device registered 
        # and should be saved for later use.
        # device_name - The random device name to use for this registration.
        # device_password - The random device password to use for this registration.
        # client_id - The app GUID, a unique id for the client/application.
        def _register_machine(device_name,device_password,client_id)
          device_registration_request =
            "<DeviceAddRequest>
              <ClientInfo name=\"#{client_id}\" version=\"1.0\"/>
              <Authentication>
                <Membername>11#{device_name}</Membername>
                <Password>#{device_password}</Password>
              </Authentication>
            </DeviceAddRequest>"
          windows_live_device_url = "https://login.live.com/ppsecure/DeviceAddCredential.srf"
          doc = send_request(windows_live_device_url,device_registration_request,nil,"application/soap+xml; charset=UTF-8")
          raise "Can't register machine with Wndows Live ID" if select_node(doc,'DeviceAddResponse/@Success').to_s.strip != 'true'
        end

        # Validate Windows Live ID response for any exception.
        # doc - The Windows Live ID service response.
        # source - An exception source.
        # Raise runtime error is request is invalid 
        def _is_response_valid(doc,source)
          if select_node(doc,'s:Fault').size > 0
            error = "Unknown error"
            begin
              reason = select_node_text(doc,'s:Reason/s:Text')
              details = select_node_text(doc,'psf:text')
              code = select_node_text(doc,'psf:code')
            error = "#{reason} (#{code}): #{details}" 
            rescue; end
            begin
              raise "#{self.name} error w/ #{source}: #{error}"
            rescue Exception => ex
              warn "#{self.name} error: " + ex.inspect.strip
              ex.backtrace.each { |line| warn 'from ' + line } 
              raise ex
            end    
          end
        end
      
        def _compose_header(user_token_id,user,password,client_id=nil,device_token=nil)
          app_info = client_id ?
            "<ps:AuthInfo Id=\"PPAuthInfo\" xmlns:ps=\"http://schemas.microsoft.com/LiveID/SoapServices/v1\">
              <ps:HostingApp>#{client_id}</ps:HostingApp>
            </ps:AuthInfo>" : ""
          binary_security_token = device_token ?
            "<wsse:BinarySecurityToken ValueType=\"urn:liveid:device\">
              #{device_token}
            </wsse:BinarySecurityToken>" : ""
          header = "
            <wsa:Action s:mustUnderstand=\"1\">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action>
            <wsa:To s:mustUnderstand=\"1\">http://Passport.NET/tb</wsa:To>  
            #{app_info}  
            <wsse:Security>
            <wsse:UsernameToken wsu:Id=\"#{user_token_id}\">
              <wsse:Username>#{user}</wsse:Username>
              <wsse:Password>#{password}</wsse:Password>
            </wsse:UsernameToken>
            #{binary_security_token}
            </wsse:Security>"
        end
      
        def _compose_body(address,policy=nil)
          policy_reference = policy ? "<wsp:PolicyReference URI=\"#{policy}\"/>" : ""
          body = "
            <wst:RequestSecurityToken Id=\"RST0\">
              <wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType>
              <wsp:AppliesTo>
                <wsa:EndpointReference>
                  <wsa:Address>#{address}</wsa:Address>
                </wsa:EndpointReference>
              </wsp:AppliesTo>
              #{policy_reference}
            </wst:RequestSecurityToken>"  
        end
        
        # Get a device authorization token from the Windows Live ID service.
        # authorization_endpoint - Authorization endpoint
        # device_name - The random device name used for this registration.
        # device_password - The random device password used for this registration.
        # Returns - The device token to use when retrieving a user token
        def _get_device_token(authorization_endpoint,device_name,device_password)
            header = _compose_header('devicesoftware',"11#{device_name}",device_password)
            body = _compose_body('http://Passport.NET/tb')
            message = compose_message(header,body)          
            # call authorization endpoint
            doc = send_request(authorization_endpoint,message,nil,"application/soap+xml; charset=UTF-8")
            # validate response and raise if invalid
            _is_response_valid(doc,"IssueDeviceToken")
            # get device token
            select_node(doc,'wst:RequestedSecurityToken/*')
        end

        # Gets a Windows Live ID RequestSecurityTokenResponse ticket for a specified user.  
        # authorization_endpoint - Authorization endpoint
        # user_name - The Windows Live ID email address for the user.
        # password - The Windows Live ID password for the user.
        # partner - sitename, i.e. crmapp.www.local-titan.com
        # policy - auth policy, i.e. MBI_SSL
        # client_id - The unique id of the client/application
        # device_token - The device token xml
        # Returns - A string that contains the Windows Live ID ticket for 
        # the supplied paramters and ticket expiration date/time
        def _get_ticket(authorization_endpoint,user_name,password,partner,policy,client_id,device_token)
            header = _compose_header('user',user_name,password,client_id,device_token)
            body = _compose_body(partner,policy)
            message = compose_message(header,body)
            # call authorization endpoint
            doc = send_request(authorization_endpoint,message,nil,"application/soap+xml; charset=UTF-8")
            # validate response and raise if invalid
            _is_response_valid(doc,"IssueTicket")
            # get ticket
            expires = DateTime.parse(select_node_text(doc,'wst:Lifetime/wsu:Expires'))
            ticket = select_node_text(doc,'wsse:BinarySecurityToken')
            [CGI::escape(ticket),expires]
        end
      end
    end
  end
end
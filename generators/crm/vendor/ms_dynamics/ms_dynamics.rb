require 'rubygems'
require 'uuidtools'
require 'rest-client'
require 'nokogiri'
require 'date'

require 'rhocrm/soap_service'
require 'vendor/ms_dynamics/lib/wlid_service'
require 'vendor/ms_dynamics/lib/discovery_service'
require 'vendor/ms_dynamics/lib/crm_service'
require 'vendor/ms_dynamics/lib/crm_metadata_service'

module Rhocrm
  module MsDynamics
    Rhocrm::SoapService.node_namespaces.merge!({'cds' => 'http://schemas.microsoft.com/crm/2007/CrmDiscoveryService',
                                                'wst' => 'http://schemas.xmlsoap.org/ws/2005/02/trust',
                                                's'   => 'http://www.w3.org/2003/05/soap-envelope',
                                                'psf' => 'http://schemas.microsoft.com/Passport/SoapServices/SOAPFault',
                                                'cws6' => 'http://schemas.microsoft.com/crm/2006/WebServices',
                                                'cws7' => 'http://schemas.microsoft.com/crm/2007/WebServices'});
    Rhocrm::SoapService.envelope_namespaces += <<-DESC
      xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" 
      xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\" 
      xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" 
      xmlns:wst=\"http://schemas.xmlsoap.org/ws/2005/02/trust\"
    DESC
    
    class << self
      def save_auth_info(username,auth_info)
        Store.put_data(auth_info_key(username),"#{username}"=>auth_info)
      end

      def load_auth_info(username)
        Store.get_data(auth_info_key(username))[username]
      end

      private
      def auth_info_key(username)
        "#{username}-msdynamics-auth-info"
      end
    end
  end
end
require 'rhoconnect-adapters'
require 'rhoconnect-adapters/soap_service'
require 'active_support/core_ext'

module RhoconnectAdapters
  module CRM
    module Salesforce
      RhoconnectAdapters::SoapService.envelope_namespaces += <<-DESC
        xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\"
      DESC
      
      class Application < Rhoconnect::Base
        class << self
          def authenticate(username,password,session=nil)
            begin
              salesforce_login_url = Application.get_settings[:salesforce_login_url]
              
              request_body = "<login xmlns=\"urn:enterprise.soap.sforce.com\"> 
                                <username>#{username}</username> 
                                <password>#{password}</password> 
                              </login>"
              
              soap_message = RhoconnectAdapters::SoapService.compose_message(nil, request_body)
              response = RhoconnectAdapters::SoapService.send_request_raw(salesforce_login_url, soap_message, '""')
              res_hash = Hash.from_xml(response)['Envelope']['Body']['loginResponse']['result']
              
              # obtain session id and endpoint url
              session_id = res_hash['sessionId'].split('!')[1]
              # here, requestUrl is formatted for SOAP requests
              # and we removing Soap part for it (which is suffix after services)
              # since we will user REST after that
              endpoint_url = res_hash['serverUrl'].split('services')[0] + 'services/data/v22.0'
              
              # store password to be used by SourceAdaptors
              Store.put_value("#{username}:session_id", session_id)
              Store.put_value("#{username}:service_url", endpoint_url)
            rescue Exception => e
              warn "Can't authenticate user #{username}: " + e.inspect
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
              file = YAML.load_file(File.join(ROOT_PATH,'vendor','salesforce','settings','settings.yml'))
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
end


{"result"=>{"metadataServerUrl"=>"https://na3-api.salesforce.com/services/Soap/m/22.0/00D50000000Iyfx", 
            "passwordExpired"=>"false", 
            "sandbox"=>"false", 
            "serverUrl"=>"https://na3-api.salesforce.com/services/Soap/c/22.0/00D50000000Iyfx", 
            "sessionId"=>"00D50000000Iyfx!ARwAQHbIfRD2GDMENzerpqNEYhbArnxFZjjfdHJAakSRy0pfqjqAZfwxCaBlUB8b2kQ0UQlKlUOi1F9isT5BUEczvvFnXq4r", 
            "userId"=>"00550000001J8xJAAS", 
            "userInfo"=>{"accessibilityMode"=>"false", "currencySymbol"=>"$", "orgAttachmentFileSizeLimit"=>"5242880", 
              "orgDefaultCurrencyIsoCode"=>"USD", "orgDisallowHtmlAttachments"=>"false", "orgHasPersonAccounts"=>"false", 
              "organizationId"=>"00D50000000IyfxEAC", "organizationMultiCurrency"=>"false", "organizationName"=>"Rhomobile", "profileId"=>"00e50000001876vAAA", 
              "roleId"=>{"xsi:nil"=>"true"}, "sessionSecondsValid"=>"7200", "userDefaultCurrencyIsoCode"=>{"xsi:nil"=>"true"}, 
              "userEmail"=>"brian@rhomobile.com", "userFullName"=>"Brian Moore", 
              "userId"=>"00550000001J8xJAAS", "userLanguage"=>"en_US", "userLocale"=>"en_US", "userName"=>"brian@rhomobile.com", 
              "userTimeZone"=>"America/Los_Angeles", "userType"=>"Standard", "userUiSkin"=>"Theme3"}}}


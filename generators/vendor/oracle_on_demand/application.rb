require 'rhocrm'
require 'rest-client'

module Rhocrm
  module OracleOnDemand
    class Application < Rhosync::Base
      class << self
        def authenticate(username,password,session)
          success = false
          begin
            oraclecrm_url = Application.get_settings[:oraclecrm_service_url]
            request_url = oraclecrm_url + "?command=" + 'login'
        
            # here we just verifying the credetials
            # by loggin in and immediately logging out
            in_headers = {
              "UserName" => username,
              "Password" => password
            };

            RestClient.get(request_url, in_headers) do |response,request,result,&block|
              case response.code
              when 200
                # store password to be used by SourceAdaptors
                Store.put_value("#{username}:password", password)
                Store.put_value("#{username}:service_url", oraclecrm_url)
            
                # since we established the session only 
                # to verify the credentials - close the session here
                request_url = "#{oraclecrm_url}" + '?command=' + 'logoff'
                in_headers = { "Cookie" => response.headers[:set_cookie] };
                RestClient.get(request_url, in_headers)
              else
                raise "LOGIN/PASSWORD ERROR : #{response.code} : #{response}" 
              end  
            end
            success = true
          rescue Exception => e
            puts "LOGIN ERROR"
            puts e.inspect
            puts e.backtrace.join("\n")
            raise e
          end
          success
        end
        def get_settings
          return @settings if @settings
          begin
            file = YAML.load_file(File.join(ROOT_PATH,'settings','settings.yml'))
            env = (ENV['RHO_ENV'] || :development).to_sym
            puts " env is : #{env} "
            @settings = file[env]
            
            # vendor-specific settings
            file = YAML.load_file(File.join(ROOT_PATH,'vendor','oracle_on_demand','settings','settings.yml'))
            @settings.merge!(file[env])
            puts " settings are : " + @settings.inspect
            @settings
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


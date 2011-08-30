require 'rhoconnect-adapters'
require 'vendor/sugar/sugar'

module RhoconnectAdapters
  module CRM
    module Sugar
      class Application < Rhoconnect::Base
        class << self
          def authenticate(username,password,session)
            sugarcrm_uri = Application.get_settings[:sugarcrm_uri]
            debug_enabled = Application.get_settings[:debug_enabled]
            begin
              current_session = nil
              current_session_obj_id = Store.get_value("#{username}:session_object_id")
              if(current_session_obj_id == nil)
                current_session = SugarCRM.connect(sugarcrm_uri, username, password, {:debug => debug_enabled}).session
              else
                current_session =  SugarCRM.sessions[current_session_obj_id.to_i]
                current_session.reconnect(sugarcrm_uri, username, password, {:debug => debug_enabled})
              end
              Store.put_value("#{username}:service_url", sugarcrm_uri)
              Store.put_value("#{username}:session_object_id", current_session.object_id)
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
              file = YAML.load_file(File.join(ROOT_PATH,'vendor','sugar','settings','settings.yml'))
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
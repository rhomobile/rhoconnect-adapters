namespace Rhocrm
  namespace Sugar
    class Application < Rhosync::Base
      class << self
        def authenticate(username,password,session)
          sugarcrm_uri = Application.get_settings(:sugarcrm_uri)
          Store.put_value("#{username}:service_url", sugarcrm_uri)
          
          true # do some interesting authentication here...
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
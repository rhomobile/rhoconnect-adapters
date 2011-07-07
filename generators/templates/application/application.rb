require 'vendor/<%=underscore_crm%>/application'

class Application < Rhocrm::<%=crm_name%>::Application
  class << self
    def backend
      '<%=underscore_crm%>'
    end
    
    def authenticate(username,password,session)
      super(username, password, session) 
      # override the default behaviour here
    end
    
    # Add hooks for application startup here
    # Don't forget to call super at the end!
    def initializer(path)
      super
    end
    
    # Calling super here returns rack tempfile path:
    # i.e. /var/folders/J4/J4wGJ-r6H7S313GEZ-Xx5E+++TI
    # Note: This tempfile is removed when server stops or crashes...
    # See http://rack.rubyforge.org/doc/Multipart.html for more info
    # 
    # Override this by creating a copy of the file somewhere
    # and returning the path to that file (then don't call super!):
    # i.e. /mnt/myimages/soccer.png
    def store_blob(object,field_name,blob)
      super #=> returns blob[:tempfile]
    end
  end
end

Application.initializer(ROOT_PATH)
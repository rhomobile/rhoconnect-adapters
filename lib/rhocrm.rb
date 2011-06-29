require "rhocrm/version"

module Rhocrm
  class Field
    class << self
      def create(name,type,label=nil)
        { name => { :type => type,
                    :label => label.nil? ? name : label }}
      end
      
      def load_file(filename,key=nil)
        contents = YAML.load_file(filename)
        return key.nil? ? contents : contents[key]
      end
    end
  end    
end

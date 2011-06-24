require "rhocrm/version"

module Rhocrm
  class Field
    class << self
      def create(name,type,label=nil)
        { name => { :type => type,
                    :label => label.nil? ? name : label }}
      end
    end
  end    
end

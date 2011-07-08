require 'rhocrm'
require 'rhocrm/soap_service'

module Rhocrm
  module MsDynamics
    class Adapter < SourceAdapter 
      class << self
      end
    end
    
    def initialize(source)
      super(source)
      puts "Initializing MsDynamics " + self.class.to_s + " SourceAdapter"
      @fields = {}      
    end
    
    def configure_fields
      # initialize object's fields here
      # and return them as a result
      fields
    end
  end
end
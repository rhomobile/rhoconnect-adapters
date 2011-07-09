require 'rhocrm'
require 'rhocrm/soap_service'

module Rhocrm
  module MsDynamics
    class Adapter < SourceAdapter
      attr_accessor :crm_object
      attr_accessor :fields
      
      def initialize(source)
        super(source)
        @crm_object = self.class.name
        @fields = {}      
      end
    
      def configure_fields
        # initialize object's fields here
        # and return them as a result
        fields
      end
    end
  end
end
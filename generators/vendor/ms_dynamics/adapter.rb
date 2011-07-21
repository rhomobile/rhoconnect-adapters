require 'rhocrm'
require 'vendor/ms_dynamics/ms_dynamics'

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
        # initialize fields map
        @fields = get_object_settings['Query_Fields']
        
        @field_picklists = {}
        static_picklists = get_object_settings['StaticPicklist']
        if static_picklists != nil
          static_picklists.each do |element_name, values|
            @field_picklists[element_name] = values
          end
        end
    
        @object_fields = get_object_settings['ObjectFields']
        @object_fields = {} if @object_fields == nil
        
        @fields
      end
      
      def get_object_settings
        return @object_settings if @object_settings
        begin
          @object_settings = Rhocrm::Field.load_file(File.join(ROOT_PATH,'vendor','ms_dynamics','settings',"#{crm_object.downcase}.yml"))
        rescue Exception => e
          puts "Error opening CRMObjects settings file: #{e}"
          puts e.backtrace.join("\n")
          raise e
        end
      end
      
      def login
        auth_info = Rhocrm::MsDynamics.load_auth_info("#{current_user.login}")
        @endpoint_url = auth_info['crm_service_url']
        @crm_service = Rhocrm::MsDynamics::CrmService.new(@endpoint_url, auth_info['crm_ticket'], auth_info['user_organization'])
      end
      
      def query(params=nil)
        # TODO: Query your backend data source and assign the records 
        # to a nested hash structure called @result. For example:
        # @result = { 
        #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
        #   "2"=>{"name"=>"Best", "industry"=>"Software"}
        # }
        @result = {}
        attributes = fields.keys
        @result = @crm_service.retrieve_multiple(crm_object.downcase,attributes)
      end
      
      def create(create_hash,blob=nil)
        # TODO: Create a new record in your backend data source
        # If your rhodes rhom object contains image/binary data 
        # (has the image_uri attribute), then a blob will be provided
        created_object_id = nil
        request_fields = {}
        fields.each do |element_name, element_def|
          field_value = create_hash[element_name]
          if field_value != nil and element_name != "#{crm_object.downcase}id"
            request_fields[element_name] = field_value
          end
        end
        
        created_object_id = @crm_service.create(crm_object.downcase, request_fields)
      end
      def update(update_hash)
        updated_object_id = update_hash["#{crm_object.downcase}id"]
        if updated_object_id == nil
          raise SourceAdapterObjectConflictError "'#{crm_object.downcase}id' field must be specified for the Update request"
        end
        
        request_fields = {}
        fields.each do |element_name,element_def|
          next unless element_name != "#{crm_object.downcase}id"
          
          field_value = update_hash[element_name]
          if field_value != nil
            request_fields[element_name] = field_value
          end
        end
        
        @crm_service.update(crm_object.downcase, updated_object_id, request_fields)
        updated_object_id
      end
 
      def delete(delete_hash)
        deleted_object_id = delete_hash["#{crm_object.downcase}id"]
        
        if deleted_object_id == nil
          raise SourceAdapterObjectConflictError "'#{crm_object.downcase}id' field must be specified for the Delete request"
        end
        
        @crm_service.delete(crm_object.downcase, deleted_object_id)
        deleted_object_id
      end
 
      def logoff
        # logoff if necessary
      end
    end
  end
end
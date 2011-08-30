require 'rhoconnect-adapters'
require 'vendor/ms_dynamics/ms_dynamics'
require 'active_support/inflector'

module RhoconnectAdapters
  module CRM
    module MsDynamics
      class Adapter < SourceAdapter
        attr_accessor :crm_object
        attr_accessor :fields
      
        def initialize(source)
          super(source)
          @crm_object = self.class.name
          @fields = {}   
          @title_fields = ["#{crm_object.downcase}id"]   
        end
    
        def configure_fields
          # initialize fields map
          @fields = get_object_settings['Query_Fields']
          @field_picklists = {}
        
          # obtain attribute type picklists
          @attrtype_picklists = {}
          attribute_type_picklists = get_object_settings['AttributeTypePicklists']
          if attribute_type_picklists != nil
            attribute_type_picklists.each do |element_name, values|
              @attrtype_picklists[element_name] = values
            end
          end
    
          @object_fields = get_object_settings['ObjectFields']
          @object_fields = {} if @object_fields == nil
        
          # title fields are used in metadata to show 
          # records in the list
          @title_fields = get_object_settings['TitleFields']
        
          @fields
        end
      
        def get_object_settings
          return @object_settings if @object_settings
          begin
            @object_settings = RhoconnectAdapters::CRM::Field.load_file(File.join(ROOT_PATH,'vendor','ms_dynamics','settings',"#{crm_object.downcase}.yml"))
          rescue Exception => e
            puts "Error opening CRMObjects settings file: #{e}"
            puts e.backtrace.join("\n")
            raise e
          end
        end
      
        def get_picklists
          begin  
            fields.each do |element_name, element_def|
              # exclude artificial attribute type fields
              next if @attrtype_picklists.has_key?(element_name)
              data_type = element_def['Type']
              # for picklists - get values
              # but only for those that are not 
              # already defined statically
              if data_type == 'Picklist' and not @field_picklists.has_key?(element_name)
                @field_picklists[element_name] = get_picklist(element_name)
              end
            end    
          rescue RestClient::Exception => e
            raise e
          end
        end
 
        def get_picklist(element_name)
          # check if we already have it in Store
          picklist = Store.get_data("#{crm_object}:#{element_name}_picklist",Hash)
          return picklist['picklist_vals'] if picklist.size != 0
        
          field_values = @crm_metadata_service.request_picklist("#{crm_object.downcase}",element_name)
          Store.put_data("#{crm_object}:#{element_name}_picklist", { 'picklist_vals' => field_values })
          field_values
        end
      
        def login
          auth_info = RhoconnectAdapters::CRM::MsDynamics.load_auth_info("#{current_user.login}")
          @endpoint_url = auth_info['crm_service_url']
          @crm_service = RhoconnectAdapters::CRM::MsDynamics::CrmService.new(@endpoint_url, auth_info['crm_ticket'], auth_info['user_organization'])
          @crm_metadata_service = RhoconnectAdapters::CRM::MsDynamics::CrmMetadataService.new(auth_info['crm_metadata_service_url'], auth_info['crm_ticket'], auth_info['user_organization'])
          # query picklist values
          get_picklists
        end
      
        def query(params=nil)
          # TODO: Query your backend data source and assign the records 
          # to a nested hash structure called @result. For example:
          # @result = { 
          #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
          #   "2"=>{"name"=>"Best", "industry"=>"Software"}
          # }
          @result = {}
        
          attributes = []
          # strip out artificial 'attrtype' fields
          fields.each do |key, val|
            attributes << key unless key.index('_attrtype') != nil
          end
        
          @result = @crm_service.retrieve_multiple(crm_object.downcase,attributes,@field_picklists)
        end
      
        def metadata
          # define the metadata
          show_fields = []
          new_fields = []
          edit_fields = []
          model_name = "" + crm_object
          model_name[0] = model_name[0,1].downcase
          record_sym = '@' + "#{model_name}"
          fields.each do |element_name,element_def|
            next if element_name == "#{crm_object.downcase}id"
      
            # 1) - read-only show fields
            field_type = 'labeledvalueli'
            field = {
              :name => "#{model_name}\[#{element_name}\]",
              :label => element_def['Label'],
              :type => field_type,
              :value => "{{#{record_sym}/#{element_name}}}"
            }
            show_fields << field
      
            new_field = field.clone
            new_field[:type] = 'labeledinputli'
            new_field.delete(:value) 
            case element_def['Type']
            when 'Picklist'
              new_field[:type] = 'select'
              values = []
              # attribute type fields should be treated specially
              if element_name.index('_attrtype') != nil
                values.concat @attrtype_picklists[element_name]
              else 
                values[0] = nil
                values.concat @field_picklists[element_name].values
              end
              new_field[:values] = values
              new_field[:value] = values[0]
            when 'object'
            end
             
            new_fields << new_field if not element_def['Type'] == 'object'
      
            edit_field = new_field.clone
            edit_field[:value] = "{{#{record_sym}/#{element_name}}}"
            edit_fields << edit_field
          end
    
          # Show
          show_list = { :name => 'list', :type => 'list', :children => show_fields }
          show_form = { 
            :name => "#{crm_object}_show",
            :type => 'show_form',
            :title => "#{crm_object} details",
            :object => "#{crm_object}",
            :model => "#{model_name}",
            :id => "{{#{record_sym}/object}}",
            :children => [show_list]
          }
    
          # New
          new_list = show_list.clone
          new_list[:children] = new_fields
          new_form = {
            :type => 'new_form',
            :title => "New #{crm_object}",
            :object => "#{crm_object}",
            :model => "#{model_name}",
            :children => [new_list]
          }
    
          # Edit
          edit_list = show_list.clone
          edit_list[:children] = edit_fields
          edit_form = { 
            :type => 'update_form',
            :title => "Edit #{crm_object}",
            :object => "#{crm_object}",
            :model => "#{model_name}",
            :id => "{{#{record_sym}/object}}",
            :children => [edit_list]
          }
        
          # Index
          title_field_metadata = @title_fields.collect { |field_name | "{{#{field_name.to_s}}} " }.join(' ')
          object_rec = {
            :object => "#{crm_object}",
            :id => "{{object}}",
            :type => 'linkobj', 
            :text => "#{title_field_metadata}" 
          }

          index_form = {
            :title => "#{crm_object.pluralize}",
            :object => "#{crm_object}",
            :type => 'index_form',
            :children => [object_rec],
            :repeatable => "{{#{record_sym.pluralize}}}"
          }
        
          # return JSON
          { 'index' => index_form, 'show' => show_form, 'new' => new_form, 'edit' => edit_form }.to_json
        end
      
        def create(create_hash,blob=nil)
          # TODO: Create a new record in your backend data source
          # If your rhodes rhom object contains image/binary data 
          # (has the image_uri attribute), then a blob will be provided
          created_object_id = nil
          request_fields = {}
          field_types = {}
          fields.each do |element_name, element_def|
            field_value = create_hash[element_name]
          
            # special case scenario where the field is
            # actually a 'type' attribute of another field
            type_index = element_name.index('_attrtype')
            if type_index != nil
              field_name = element_name.slice(0, type_index)
              field_types[field_name] = field_value
              next
            end
          
            # convert Picklist field values from User-friendly form
            # into Integers that are accepted by MsDynamics
            if @field_picklists.has_key?(element_name)
              field_picklist_indexes = @field_picklists[element_name].invert
              field_value = field_picklist_indexes[field_value]
            end
          
            if field_value != nil and element_name != "#{crm_object.downcase}id"
              request_fields[element_name] = field_value
            end
          end
        
          created_object_id = @crm_service.create(crm_object.downcase, request_fields, field_types)
        end
        def update(update_hash)
          # it may be there as 'id' field
          updated_object_id = update_hash["#{crm_object.downcase}id"] || update_hash['id']
          if updated_object_id == nil
            raise SourceAdapterObjectConflictError.new("Either '#{crm_object.downcase}id' or 'id' field must be specified for the Update request")
          end
        
          request_fields = {}
          field_types = {}
          fields.each do |element_name,element_def|
            next unless element_name != "#{crm_object.downcase}id"
          
            field_value = update_hash[element_name]
          
            # special case scenario where the field is
            # actually a 'type' attribute of another field
            type_index = element_name.index('_attrtype')
            if type_index != nil
              field_name = element_name.slice(0, type_index)
              field_types[field_name] = field_value
              next
            end
          
            # convert Picklist field values from User-friendly form
            # into Integers that are accepted by MsDynamics
            if @field_picklists.has_key?(element_name)
              field_picklist_indexes = @field_picklists[element_name].invert
              field_value = field_picklist_indexes[field_value]
            end
          
            if field_value != nil
              request_fields[element_name] = field_value
            end
          end
        
          @crm_service.update(crm_object.downcase, updated_object_id, request_fields, field_types)
          updated_object_id
        end
 
        def delete(delete_hash)
          deleted_object_id = delete_hash["#{crm_object.downcase}id"] || delete_hash['id']
        
          if deleted_object_id == nil
            raise SourceAdapterObjectConflictError.new("Either '#{crm_object.downcase}id' or 'id' field must be specified for the Delete request")
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
end
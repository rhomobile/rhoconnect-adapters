require 'rhoconnect-adapters'
require 'rest-client'

module RhoconnectAdapters
  module CRM
    module Salesforce
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
            @object_settings = RhoconnectAdapters::CRM::Field.load_file(File.join(ROOT_PATH,'vendor','salesforce','settings',"#{crm_object}.yml"))
          rescue Exception => e
            puts "Error opening CRMObjects settings file: #{e}"
            puts e.backtrace.join("\n")
            raise e
          end
        end
      
        def get_picklists
          begin 
            already_described = Store.get_value("#{crm_object}:already_described")
            # call describe method to retrieve the object's metadata
            if not already_described
              request_url = "#{@resturl}/sobjects/#{crm_object}/describe/"
              parsed = JSON.parse(RestClient.get(request_url, @restheaders).body)
              parsed["fields"].each do |field|
                element_name = field['name']
              
                next unless fields[element_name] != nil
                data_type = fields[element_name]['Type']
                if data_type == 'Picklist' and not @field_picklists.has_key?(element_name)
                  @field_picklists[element_name] = get_picklist(element_name, field)
                end
              end
              Store.put_value("#{crm_object}:already_described", true)
            # object is already described - data should be in the Store
            else
              fields.each do |element_name, element_def|
                if element_def['Type'] == 'Picklist' and not @field_picklists.has_key?(element_name)
                  @field_picklists[element_name] = Store.get_data("#{crm_object}:#{element_name}_picklist",Array)
                end
              end
            end 
          rescue RestClient::Exception => e
            raise e
          end
        end
 
        def get_picklist(element_name, field_data)
          # check if we already have it in Store
          picklist = Store.get_data("#{crm_object}:#{element_name}_picklist",Array)
          return picklist if picklist.size != 0
        
          field_values = []
          field_data["picklistValues"].each do |v|
            field_values << v['value']
          end
          Store.put_data("#{crm_object}:#{element_name}_picklist", field_values)
          field_values
        end
      
        def login
          @session_id = Store.get_value("#{current_user.login}:session_id")
          @resturl = Store.get_value("#{current_user.login}:service_url")
          @restheaders = {
            "Accept" => "*/*", 
            "Authorization" => "OAuth #{@session_id}", 
            "X-PrettyPrint" => "1"
          }

          @postheaders = {
            "Accept" => "*/*", 
            "Content-Type" => "application/json", 
            "Authorization" => "OAuth #{@session_id}", 
            "X-PrettyPrint" => "1"
          }
          
          # query picklist values
          get_picklists
        end
      
        def query(params=nil)
          #
          # Straightforward way to query data. Dot not fit for large result sets.
          #
          # @result = {}
          # fieldquery = ""
          # @fields.each do |element_name, element_def|
          #   fieldquery << ",#{element_name}"
          # end
          # fieldquery[0] = " "
          #
          # querystr = "SELECT #{fieldquery} FROM #{crm_object}"
          # requesturl = @resturl + "/query/?q=" + CGI::escape(querystr)
          # raw_data = RestClient.get(requesturl, @restheaders)
          # parsed_data = JSON.parse raw_data
          #
          # if parsed_data['done']
          #   parsed_data["records"].each do |record|
          #     record_hash = {}
          #     @fields.each do |element_name, element_def|
          #       record_hash[element_name] = record[element_name]
          #     end
          #     @result[record['Id']] = record_hash
          #   end
          # else
          #   # TODO: queryMore
          # end
          # @result

          fieldquery = ""
          @fields.each do |element_name, element_def|
            fieldquery << ",#{element_name}"
          end
          fieldquery[0] = " "

          # Paginate into (large) result sets staring with offset = 0 and page_sz = 100
          offset, page_sz = 0, 100
          loop do
            querystr = "SELECT #{fieldquery} from #{crm_object} limit #{page_sz} offset #{offset}"
            requesturl = @resturl + "/query/?q=" + CGI::escape(querystr)
            raw_data = RestClient.get(requesturl, @restheaders)
            parsed_data = JSON.parse raw_data

            @result ||= {}
            parsed_data["records"].each do |record|
              record_hash = {}
              @fields.each do |element_name, element_def|
                record_hash[element_name] = record[element_name]
              end
              @result[record['Id']] = record_hash
            end
            stash_result # => @result is nil now
            break if parsed_data['done']
            offset += page_sz
          end
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
            next if element_name == 'Id'
      
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
              # make first element a blank value
              values[0] = nil
              values.concat @field_picklists[element_name] if @field_picklists[element_name]
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
            :object => "#{crm_object}",
            :title => "#{crm_object.pluralize}",
            :type => 'index_form',
            :children => [object_rec],
            :repeatable => "{{#{record_sym.pluralize}}}"
          }

          # return JSON
          { 'index' => index_form, 'show' => show_form, 'new' => new_form, 'edit' => edit_form }.to_json  
        end
        
        def create(create_hash)
          # TODO: Create a new record in your backend data source
          # If your rhodes rhom object contains image/binary data 
          # (has the image_uri attribute), then a blob will be provided
          created_object_id = nil
          request_fields = {}
          field_types = {}
          fields.each do |element_name, element_def|
            field_value = create_hash[element_name]
            next unless (element_name != "Id" and field_value != nil)
            
            # special case for Datetime types - they need to 
            # be converted to W3C XML trailing Z
            if element_def['Type'] == 'datetime'
              field_value = Date.parse(field_value).strftime '%Y-%m-%dT%H:%M:%S.000Z'
            end  
            request_fields[element_name] = field_value
          end
          
          begin 
            requesturl = "#{@resturl}/sobjects/#{crm_object}/"
            raw_data = RestClient.post(requesturl, request_fields.to_json, @postheaders) do |response,request, result, &block| 
              case response.code 
              when 400
                raise response.body
              end
              response.body
            end
            parsed = JSON.parse raw_data
            created_object_id = parsed['id']
          rescue Exception => e
            raise e
          end
          created_object_id
        end
        
        def update(update_hash)
          # it may be there as 'id' field
          updated_object_id = update_hash['Id'] || update_hash['id']
          if updated_object_id == nil
            raise SourceAdapterObjectConflictError.new("Either 'Id' or 'id' field must be specified for the Update request")
          end
        
          request_fields = {}
          field_types = {}
          fields.each do |element_name,element_def|
            next if (element_name == "Id" or element_name == 'id')
          
            field_value = update_hash[element_name]
            next unless field_value != nil
            # special case for Datetime types - they need to 
            # be converted to W3C XML trailing Z
            if element_def['Type'] == 'datetime'
              field_value = Date.parse(field_value).strftime '%Y-%m-%dT%H:%M:%S.000Z'
            end
            request_fields[element_name] = field_value
          end
          
          requesturl = @resturl + "/sobjects/#{crm_object}/#{updated_object_id}?_HttpMethod=PATCH"
          RestClient.post(requesturl, request_fields.to_json, @postheaders)
          updated_object_id
        end
        
        def delete(delete_hash)
          deleted_object_id = delete_hash["Id"] || delete_hash['id']
          if deleted_object_id == nil
            raise SourceAdapterObjectConflictError.new("Either 'Id' or 'id' field must be specified for the Delete request")
          end
        
          requesturl = @resturl + "/sobjects/#{crm_object}/#{deleted_object_id}?_HttpMethod=DELETE"
          RestClient.post(requesturl, "", @postheaders)
          deleted_object_id
        end
 
        def logoff
          # logoff if necessary
        end
      end
    end
  end
end
require 'rhocrm'
require 'rhocrm/soap_service'

module Rhocrm
  module OracleOnDemand
    Rhocrm.node_namespaces.merge!({'plns' => 'urn:crmondemand/ws/picklist/',
                                   'pldoc' => 'urn:/crmondemand/xml/picklist'});
    class Adapter < SourceAdapter 
      class << self
        def get_columns(fields)
          columns = ""
          fields.each do |key,val|
            columns += "<wsdl:#{key}></wsdl:#{key}>"
          end
          columns
        end
        
        def get_columns_values(fields)
          columns = ""
          fields.each do |key,val|
            if not val
              next
            end
            columns += "<wsdl:#{key}>#{val}</wsdl:#{key}>"
          end
          columns
        end
      end
                        
      def initialize(source)
        super(source)
        puts "Initializing ORACLE CRM " + self.class.to_s + " SourceAdapter"      
      end
      
      def configure_fields
        # this is going to be used in XPath searches
        Rhocrm.node_namespaces.merge!({"#{@crm_object}doc" => "urn:/crmondemand/xml/#{@crm_object}/Data"});
        
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
          @object_settings = Rhocrm::Field.load_file(File.join(ROOT_PATH,'vendor','oracle_on_demand','settings',"#{@crm_object}.yml"))
        rescue Exception => e
          puts "Error opening CRMObjects settings file: #{e}"
          puts e.backtrace.join("\n")
          raise e
        end
      end

      def get_picklists
        begin  
          nonquery_fields = get_object_settings['NonQuery_MappingWS_Fields']
          @fields.each do |element_name, element_def|
            # use object field only of it has not been excluded
            # explicitly in the object's settings
            next if nonquery_fields.has_key? element_name
      
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
        puts "GET PICKLIST for object: #{@crm_object}, element: #{element_name}"
    
        # check if we already have it in Store
        picklist = Store.get_data("#{@crm_object}:#{element_name}_picklist",Array)
        return picklist if picklist.size != 0
        
        password = Store.get_value("#{current_user.login}:password")
        wsse = SoapService.create_wsse_header(current_user.login, password)
        body = "<wsdl:PicklistWS_GetPicklistValues_Input>
                   <wsdl:RecordType>#{@crm_object}</wsdl:RecordType>
                   <wsdl:FieldName>#{element_name}</wsdl:FieldName>
                 </wsdl:PicklistWS_GetPicklistValues_Input>"
        req = SoapService.compose_message(wsse, body, "xmlns:wsdl=\"urn:crmondemand/ws/picklist/\"")
        
        field_values = []
        response = nil
        begin
          response = SoapService.send_request("#{@endpoint_url}/GetPicklistValues",
                                              req, 
                                              "\"document/urn:crmondemand/ws/picklist/:GetPicklistValues\"",
                                              @session_cookie);
          
          oracle_rec = SoapService.select_node(Nokogiri::XML(response), '//pldoc:PicklistValue')
          oracle_rec.each do |pval|
            disabled = SoapService.select_node_text(pval, 'pldoc:Disabled')
            field_values << SoapService.select_node_text(pval, 'pldoc:DisplayValue') if not disabled == 'Y'
          end
    
        rescue RestClient::Exception => e
          raise e
        end
        # server stateless session id is returned with the response
        @session_cookie = response.cookies
    
        Store.put_data("#{@crm_object}:#{element_name}_picklist", field_values)
    
        field_values
      end
 
      def login
        puts "LOGIN USER: #{current_user.login}" 
        @endpoint_url = Store.get_value("#{current_user.login}:service_url")
    
        # get types information from the GetPicklistValues WS
        get_picklists
      end

      def execute_soap_action(action, soap_body)
        action_prefix = "#{@crm_object}" + action
        soapaction = "\"document/urn:crmondemand/ws/ecbs/#{@crm_object.downcase}/:"
        soapaction += action_prefix + '"'
        
        password = Store.get_value("#{current_user.login}:password")
        wsse = SoapService.create_wsse_header(current_user.login, password)
        body = "<wsdl:#{@crm_object}#{action}_Input>
                #{soap_body}
              </wsdl:#{@crm_object}#{action}_Input>"
        req = SoapService.compose_message(wsse, body, "xmlns:wsdl=\"urn:crmondemand/ws/ecbs/#{@crm_object.downcase}/\"")
        
        response = nil
        begin
          response = SoapService.send_request("#{@endpoint_url}/#{@crm_object}",
                                              req, 
                                              soapaction,
                                              @session_cookie);
        rescue RestClient::Error => e
          raise e
        end
        # server stateless session id is returned with the response
        @session_cookie = response.cookies
        
        SoapService.select_node(Nokogiri::XML(response), "//#{@crm_object}doc:ListOf#{@crm_object}")[0]
      end  

      def query(params=nil)
        # TODO: Query your backend data source and assign the records 
        # to a nested hash structure called @result. For example:
        # @result = { 
        #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
        #   "2"=>{"name"=>"Best", "industry"=>"Software"}
        # }
        @result = {}
        fetch_more = 'true'
        start_row = 0
        begin 
          
          soap_body = "<wsdl:ListOf#{@crm_object} recordcountneeded=\"true\" pagesize=\"100\" startrownum=\"#{start_row.to_s}\">
            <wsdl:#{@crm_object} searchspec=\"\">
              #{Adapter.get_columns(@fields)}
            </wsdl:#{@crm_object}>
          </wsdl:ListOf#{@crm_object}>"

          query_results = execute_soap_action('QueryPage', soap_body)
          fetch_more = query_results['lastpage'] == 'true' ? false : true;
          
          query_results.children.each do |record|
            if record.name == "#{@crm_object}"
               id_field = SoapService.select_node_text(record, "#{@crm_object}doc:Id")
               converted_record = {}
               # grab only the allowed fields 
               # and map oracle field names into RhoSync field names
               @fields.each do |element_name,element_def|
                 converted_record[element_name] = SoapService.select_node_text(record, "#{@crm_object}doc:#{element_name}")
               end
               @result[id_field] = converted_record
             end
           end
           start_row = @result.size
         end while fetch_more
         @result
       end
          
      def sync
        # Manipulate @result before it is saved, or save it 
        # yourself using the Rhosync::Store interface.
        # By default, super is called below which simply saves @result
        super
      end
  
      def metadata
        # define the metadata
        show_fields = []
        new_fields = []
        edit_fields = []
        model_name = "" + @crm_object
        model_name[0] = model_name[0,1].downcase
        record_sym = '@' + "#{model_name}"
        @fields.each do |element_name,element_def|
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
            values[0] = nil
            values.concat @field_picklists[element_name]
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
          :name => "#{@crm_object}_show",
          :type => 'show_form',
          :title => "#{@crm_object} details",
          :object => "#{@crm_object}",
          :model => "#{model_name}",
          :id => "{{#{record_sym}/Id}}",
          :children => [show_list]
        }
    
        # New
        new_list = show_list.clone
        new_list[:children] = new_fields
        new_form = {
          :type => 'new_form',
          :title => "New #{@crm_object}",
          :object => "#{@crm_object}",
          :model => "#{model_name}",
          :children => [new_list]
        }
    
        # Edit
        edit_list = show_list.clone
        edit_list[:children] = edit_fields
        edit_form = { 
          :type => 'update_form',
          :title => "New #{@crm_object}",
          :object => "#{@crm_object}",
          :model => "#{model_name}",
          :id => "{{#{record_sym}/Id}}",
          :children => [edit_list]
        }

        # return JSON
        { 'show' => show_form, 'new' => new_form, 'edit' => edit_form }.to_json
      end
 
      def create(create_hash,blob=nil)
        # TODO: Create a new record in your backend data source
        # If your rhodes rhom object contains image/binary data 
        # (has the image_uri attribute), then a blob will be provided
        created_object_id = nil
        request_fields = {}
        @fields.each do |element_name, element_def|
          field_value = create_hash[element_name]
          if field_value != nil and element_name != 'Id'
            request_fields[element_name] = field_value
          end
        end
        
        soap_body = "<wsdl:ListOf#{@crm_object}>
            <wsdl:#{@crm_object}>
              #{Adapter.get_columns_values(request_fields)}
            </wsdl:#{@crm_object}>
          </wsdl:ListOf#{@crm_object}>"

        begin 
          oracle_rec = execute_soap_action('Insert', soap_body)
          created_object_id = SoapService.select_node_text(oracle_rec, "//#{@crm_object}doc:Id").to_s
        rescue RestClient::Error => e
          raise e
        end
        
        # return new object ids
        created_object_id
      end
 
      def update(update_hash)
        updated_object_id = nil
        request_fields = {}
        @fields.each do |element_name,element_def|
          field_value = update_hash[element_name]
          if field_value != nil
            request_fields[element_name] = field_value
          end
        end
        # check if 'Id' is present
        # it may be available as an 'id'
        if request_fields['Id'] == nil
          request_fields['Id'] = update_hash['id']
        end
        
        soap_body = "<wsdl:ListOf#{@crm_object}>
            <wsdl:#{@crm_object}>
              #{Adapter.get_columns_values(request_fields)}
            </wsdl:#{@crm_object}>
          </wsdl:ListOf#{@crm_object}>"

        begin 
          oracle_rec = execute_soap_action('Update', soap_body)
          updated_object_id = SoapService.select_node_text(oracle_rec, "#{@crm_object}doc:Id")
        rescue RestClient::Error => e
          raise e
        end
        updated_object_id
      end
 
      def delete(delete_hash)
        deleted_object_id = nil
        request_fields = {}

        @fields.each do |element_name,element_def|
          field_value = delete_hash[element_name]
          if field_value != nil
            request_fields[element_name] = field_value
          end
        end
        soap_body = "<wsdl:ListOf#{@crm_object}>
            <wsdl:#{@crm_object}>
              #{Adapter.get_columns_values(request_fields)}
            </wsdl:#{@crm_object}>
          </wsdl:ListOf#{@crm_object}>"

        begin 
          execute_soap_action('Delete', soap_body)
          deleted_object_id = delete_hash['Id']
        rescue RestClient::Error => e
          raise e
        end
        
        deleted_object_id
      end
 
      def logoff
        # logoff if necessary
      end
    end
  end
end
require 'rhocrm'
require 'rest-client'
require 'savon'


module Rhocrm
  module OracleOnDemand
    class Adapter < SourceAdapter 
      def initialize(source,credential)
        super(source, credential)
        puts "Initializing ORACLE CRM " + self.class.to_s + " SourceAdapter"
        @oraclecrm_object = "#{self.class.to_s}"
        @soap_client = Savon::Client.new
        # comment the following lines 
        # to see the SOAP request going over the HTTP
        Savon.configure do |config|
          config.log = false
        end
        @soap_client.wsdl.document = File.join(ROOT_PATH, 'vendor','oracle_on_demand','wsdl', "#{@oraclecrm_object}.wsdl")
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
          @object_settings = YAML.load_file(File.join(ROOT_PATH,'vendor','oracle_on_demand','settings',"#{@oraclecrm_object}.yml"))
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
        rescue Savon::Error => e
          raise e
        end
      end
 
      def get_picklist(element_name)
        puts "GET PICKLIST for object: #{@oraclecrm_object}, element: #{element_name}"
    
        # check if we already have it in Store
        picklist = Store.get_data("#{@oraclecrm_object}:#{element_name}_picklist",Array)
        return picklist if picklist.size != 0
    
        picklist_client = Savon::Client.new
        picklist_client.wsdl.document = File.join(ROOT_PATH,'vendor','oracle_on_demand','wsdl','Picklist.wsdl')
        password = Store.get_value("#{current_user.login}:password")
        # credentials will be passed with every request (stateless)
        picklist_client.wsse.credentials("#{current_user.login}", password)
        picklist_client.wsdl.endpoint = @endpoint_url + '/GetPicklistValues'  

        soap_body = { "RecordType" => "#{@oraclecrm_object}",
                      "FieldName" => element_name
        };
    
        picklist_prefix = 'GetPicklistValues'
        soapaction = '"document/' + picklist_client.wsdl.namespace + ':'
        soapaction += picklist_prefix + '"'
    
        field_values = []
        begin 
          response = picklist_client.request(:wsdl, 'PicklistWS_GetPicklistValues_Input') do
            http.headers["SOAPAction"] = soapaction
            if @session_cookie != nil
              http.headers["Cookie"] = @session_cookie
            end

            soap.body = soap_body
          end
          output_data = Nori.parse(response.http.body)["SOAP_ENV:Envelope"]["SOAP_ENV:Body"]["ns:PicklistWS_GetPicklistValues_Output"]
          oracle_rec = output_data['ListOfParentPicklistValue']['ParentPicklistValue']['ListOfPicklistValue']['PicklistValue']
      
          oracle_rec.each do |pval|
            field_values << pval['DisplayValue'] if not pval['Disabled'] == 'Y'
          end
        rescue Savon::Error => e
          raise e
        end
        # server stateless session id is returned with the response
        @session_cookie = response.http.headers["Set-Cookie"]
    
        Store.put_data("#{@oraclecrm_object}:#{element_name}_picklist", field_values)
    
        field_values
      end
 
      def login
        puts "LOGIN USER: #{current_user.login}" 
        @endpoint_url = Store.get_value("#{current_user.login}:service_url")
    
        password = Store.get_value("#{current_user.login}:password")
        # credentials will be passed with every request (stateless)
        @soap_client.wsse.credentials("#{current_user.login}", password)
        @soap_client.wsdl.endpoint = @endpoint_url + "/#{self.class.to_s}"  

        # get types information from the GetPicklistValues WS
        get_picklists
      end

      def execute_soap_action(action, soap_body) 
        action_prefix = "#{@oraclecrm_object}" + action
        soapaction = '"document/' + @soap_client.wsdl.namespace + ':'
        soapaction += action_prefix + '"'
 
        response = @soap_client.request(:wsdl, action_prefix + '_Input') do
          http.headers["SOAPAction"] = soapaction
          if @session_cookie != nil
            http.headers["Cookie"] = @session_cookie
          end
          soap.body = soap_body
        end
        # server stateless session id is returned with the response
        @session_cookie = response.http.headers["Set-Cookie"]
      
        results = Nori.parse(response.http.body)["SOAP_ENV:Envelope"]["SOAP_ENV:Body"]["ns:#{action_prefix}_Output"]["ListOf#{@oraclecrm_object}"]
      end

 
      def query(params=nil)
        # TODO: Query your backend data source and assign the records 
        # to a nested hash structure called @result. For example:
        # @result = { 
        #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
        #   "2"=>{"name"=>"Best", "industry"=>"Software"}
        # }
        request_fields = {}
        @fields.each do |element_name,element_def|
          request_fields[element_name] = ''
        end
        request_body = {
          "#{@oraclecrm_object}" => request_fields,  
          :attributes! => { "#{@oraclecrm_object}" => { "searchspec" => "" } } 
        };

        @result = {}
        fetch_more = 'true'
        start_row = 0
        begin 
          soap_body = {
            "ListOf#{@oraclecrm_object}" => request_body,
            :attributes! => { 
              "ListOf#{@oraclecrm_object}" => { 
                "recordcountneeded" => true, 
                "pagesize" => "100", 
                "startrownum" => "#{start_row.to_s}" 
              }
            }
          }
 
          query_results = execute_soap_action('QueryPage', soap_body)
          fetch_more = query_results['@lastpage'] == 'true' ? false : true

          query_results.each do |objname,records|
            if objname == "#{@oraclecrm_object}"
              # in case of single record - it comes as a Hash
              # otherwise it is an array of record Hashes
              if records.is_a?Hash
                records = [records]
              end
              records.each do |oracle_rec|
                id_field = oracle_rec['Id']
                converted_record = {}
                #converted_record['id'] =  id_field
                # grab only the allowed fields 
                # and map oracle field names into RhoSync field names
                @fields.each do |element_name,element_def|
                  converted_record[element_name] = "#{oracle_rec[element_name]}"
                end
                @result[id_field] = converted_record
              end
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
        model_name = "" + @oraclecrm_object
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
          :name => "#{@oraclecrm_object}_show",
          :type => 'show_form',
          :title => "#{@oraclecrm_object} details",
          :object => "#{@oraclecrm_object}",
          :model => "#{model_name}",
          :id => "{{#{record_sym}/Id}}",
          :children => [show_list]
        }
    
        # New
        new_list = show_list.clone
        new_list[:children] = new_fields
        new_form = {
          :type => 'new_form',
          :title => "New #{@oraclecrm_object}",
          :object => "#{@oraclecrm_object}",
          :model => "#{model_name}",
          :children => [new_list]
        }
    
        # Edit
        edit_list = show_list.clone
        edit_list[:children] = edit_fields
        edit_form = { 
          :type => 'update_form',
          :title => "New #{@oraclecrm_object}",
          :object => "#{@oraclecrm_object}",
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
        request_body = {
          "#{@oraclecrm_object}" => request_fields 
        };

        soap_body = {
          "ListOf#{@oraclecrm_object}" => request_body
        };
 
        begin 
          oracle_rec = execute_soap_action('Insert', soap_body)
          created_object_id = oracle_rec["#{@oraclecrm_object}"]["Id"]
        rescue Savon::Error => e
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
        request_body = {
          "#{@oraclecrm_object}" => request_fields 
        };

        soap_body = {
          "ListOf#{@oraclecrm_object}" => request_body
        };
 
        begin 
          execute_soap_action('Update', soap_body)
          updated_object_id = update_hash['Id']
        rescue Savon::Error => e
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
        request_body = {
          "#{@oraclecrm_object}" => request_fields 
        };

        soap_body = {
          "ListOf#{@oraclecrm_object}" => request_body
        };
 
        begin 
          execute_soap_action('Delete', soap_body)
          deleted_object_id = delete_hash['Id']
        rescue Savon::Error => e
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

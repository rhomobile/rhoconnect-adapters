require 'rhoconnect-adapters'
require 'vendor/sugar/sugar'

module RhoconnectAdapters
  module CRM
    module Sugar
      class Adapter < SourceAdapter
        attr_accessor :crm_object
        attr_accessor :fields
      
        def initialize(source)
          super(source)
          @fields = {}   
          @crm_object = self.class.name
          @default_user_team_name = nil
          @title_fields = ['id']
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
        
          # title fields are used in metadata to show 
          # records in the list
          @title_fields = get_object_settings['TitleFields']
        
          @fields
        end

        def get_object_settings
          return @object_settings if @object_settings
          begin
            @object_settings = RhoconnectAdapters::CRM::Field.load_file(File.join(ROOT_PATH,'vendor','sugar','settings',"#{crm_object}.yml"))
          rescue Exception => e
            puts "Error opening CRMObjects settings file: #{e}"
            puts e.backtrace.join("\n")
            raise e
          end
        end

        def get_picklists
          begin  
            fields.each do |element_name, element_def|
              data_type = element_def['Type']
              # for picklists - get values
              # but only for those that are not 
              # already defined
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
          picklist = Store.get_data("#{crm_object}:#{element_name}_picklist",Array)
          return picklist if picklist.size != 0
        
          field_options = get_module._module.fields[element_name]['options']
          Store.put_data("#{crm_object}:#{element_name}_picklist", field_options.keys)
          field_options.keys
        end
      
        def get_user_team_name
          # retrieve default user team id (it is needed in create method)
          return @default_user_team_name unless @default_user_team_name == nil
        
          @default_user_team_name = Store.get_value("#{current_user.login}:default_user_team_name")
          if @default_user_team_name == nil
            team_id = @namespace.session.connection.get_user_team_id
            team_id.gsub!(/^"(.*?)"$/,'\1')
            team_mod = @namespace.const_get('Team')
            @default_user_team_name = team_mod.find_by_id(team_id).name
            Store.set_value("#{current_user.login}:default_user_team_name", @default_user_team_name)
          end
          @default_user_team_name
        end
      
        def login
          @uri = Store.get_value("#{current_user.login}:service_url")
          session_object_id = Store.get_value("#{current_user.login}:session_object_id")
          session_cur = SugarCRM.sessions[session_object_id.to_i]
          @namespace = SugarCRM.sessions[session_object_id.to_i].namespace_const
        
          # obtain default user's Team Name (used in create operations)
          get_user_team_name
        
          # get options for object's attributes
          get_picklists
        end

        def query(params=nil)
          @result = {}
          conditions = {:conditions=>{}}
          conditions[:conditions][:assigned_user_id] = @namespace.current_user.id
          results = get_results(conditions)
        
          @result = create_result_hash(results)
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
            next if element_name == 'id'
      
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
              values.concat @field_picklists[element_name]
              new_field[:values] = values
              new_field[:value] = values[0]
            when 'object'
            end
             
            new_fields << new_field
      
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
            :id => "{{#{record_sym}/object}}}",
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
      
        def sync
          # Manipulate @result before it is saved, or save it
          # yourself using the Rhoconnect::Store interface.
          # By default, super is called below which simply saves @result
          super
        end

        def create(create_hash)
          new_obj = get_module.new
          attributes = new_obj.attributes
          copy_keys_to_obj(create_hash, new_obj)
          new_obj.send 'assigned_user_id=', @namespace.current_user.id
          new_obj.send 'team_name=', get_user_team_name
          new_obj.send 'team_count=', '1'
          new_obj.save!
          new_obj.id
        end

        def update(update_hash)
          # step 1: get the id from the update hash
          result = get_module.find_by_id(update_hash['id'])
          copy_keys_to_obj(update_hash, result)
          result.save!
          update_hash['id']
        end
      
        def delete(delete_hash)
          result = get_module.find_by_id(delete_hash['id'])
          result.delete
          delete_hash['id']
        end

        def logoff
        
        end
      
        def get_module
          @namespace.const_get(crm_object)
        end

        def get_results(conditions)
          get_module.all(conditions)
        end
      
        def copy_keys_to_obj(source_hash, target)
          keys = source_hash.keys
          keys.each do |key|
            target.send key + '=', source_hash[key]
          end
        end

        def create_result_hash(results)
          ret_hash = {}

          if results.is_a?(Array)
            results_array = results
          else
            results_array = [results]  
          end

          results_array.each do |result|
            attributes = result.attributes
            result_hash = {}

            fields.each do |element_name, element_def|
              value = attributes[element_name]
              if (value != nil && value.is_a?(Array) == false)
                result_hash[element_name] = value
              end
            end
            id = result.id
            ret_hash[id.to_s] = result_hash
          end
          ret_hash
        end
      end
    end
  end
end
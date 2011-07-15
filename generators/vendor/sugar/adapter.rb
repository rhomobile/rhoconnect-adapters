require 'rhocrm'
require 'sugar'

module Rhocrm
  module Sugar
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
      
      def login
        id = current_user.id
        @uri = Store.get_value("#{current_user.login}:service_url")
        puts('in the login method => id: ' << id)
        password = Store.get_value(id)
        puts('in the login method => password: ' << password)
        @namespace = SugarCRM.connect(@uri, id, password)
        puts('the namespace is: ' << @namespace.to_s)
      end

      def query(params=nil)
        puts('in the query method')
        #define conditions
        set_conditions
        #get the module
        results = get_results

        if (results == nil)
          puts('results are nil')
        else
          puts('results: ' << results.to_s)
        end

        create_result_hash(results)
      end

      def get_module
        puts('getting module')
        puts('module name: ' << crm_object)
        mod = @namespace.const_get(crm_object)
        puts('module: ' << mod.to_s)
        mod
      end

      def get_results
        puts('getting results')
        get_module.all(@conditions)

      end

      def set_fields(results)
        puts('setting fields')
        if @fields == nil

          fields = results[0].attributes.keys
          puts('fields: ' << fields.to_s)
        else
          fields = @fields
        end

        fields
      end

      def create_result_hash(results)
        puts('creating the result hash')
        @result = {}

        if results.is_a?(Array)
          results_array = results
        else
          results_array = [results]  
        end

        fields = set_fields(results)
        puts('fields: ' << fields.to_s)
        results_array.each do |result|
          attributes = result.attributes
          puts('attributes: ' << attributes.to_s)
          result_hash = {}

          fields.each do |field|
            value = attributes[field]

            if (value != nil && value.is_a?(Array) == false)
              result_hash[field] = value
            end

          end

          id = result.id
          @result[id.to_s] = result_hash
        end
      end

      def set_conditions
        puts('setting conditions')
        @conditions = {:conditions=>{}}
        @conditions[:conditions][:assigned_user_id] = @namespace.current_user.id
      end

      def sync
        # Manipulate @result before it is saved, or save it
        # yourself using the Rhosync::Store interface.
        # By default, super is called below which simply saves @result
        super
      end

      def copy_keys_to_obj(source_hash, target)
        keys = source_hash.keys
        puts('keys: ' << keys.to_s)
        keys.each do |key|
          target.send key + '=', source_hash[key]
          #target_attributes[key] = source_hash[key]
        end

      end


      def create(create_hash,blob=nil)
        new_obj = get_module.new
        attributes = new_obj.attributes
        copy_keys_to_obj(create_hash, new_obj)
        #attributes['assigned_user_id'] = @namespace.current_user.id
        new_obj.send 'assigned_user_id=', @namespace.current_user.id
        puts('attributes:')
        pp(attributes)
        new_obj.save!
      end

      def update(update_hash)
        # step 1: get the id from the update hash

        result = get_module.find_by_id(update_hash.delete('id'))

        copy_keys_to_obj(update_hash, result)

        result.save!

      end
      def delete(delete_hash)
        result = get_module.find_by_id(delete_hash.delete('id'))

        result.delete
      end

      def logoff
        @namespace.disconnect!
      end
    end
  end
end
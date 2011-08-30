module RhoconnectAdapters
  module CRM
    class << self 
      attr_reader :registered_backends
      attr_reader :standard_sources

      def valid_backend?(name)
        registered_backends.index(name) != nil
      end
      def standard_source?(name)
        standard_sources.index(name) != nil
      end
    end
    @registered_backends = ['MsDynamics','OracleOnDemand','Sugar'];
    @standard_sources = ['Account','Contact','Opportunity','Lead'];
  
    class Field
      class << self
        def create(name,type,label=nil)
          { name => { :type => type,
                      :label => label.nil? ? name : label }}
        end
      
        def load_file(filename,key=nil)
          contents = YAML.load_file(filename)
          return key.nil? ? contents : contents[key]
        end
      end
    end    
  end
end

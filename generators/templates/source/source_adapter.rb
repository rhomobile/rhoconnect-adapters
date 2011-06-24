require 'vendor/<%=underscore_crm%>/adapter'

class <%=class_name%> < Rhocrm::<%=crm_name%>::Adapter
  def initialize(source,credential)
    super(source, credential)
    @crmobject_name = self.class.name
    @fields = configure_fields
  end
 
end

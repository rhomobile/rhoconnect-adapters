require 'vendor/<%=underscore_crm%>/adapter'

class <%=class_name%> < Rhocrm::<%=crm_name%>::Adapter
  def initialize(source)
    super(source)
    @crm_object = self.class.name
    @fields = configure_fields
  end
 
end

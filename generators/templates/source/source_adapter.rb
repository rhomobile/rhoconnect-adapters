require 'rhocrm/<%=underscore_crm%>/adapter'

class <%=class_name%> < Rhocrm::<%=crm_name%>::Adapter
  def initialize(source,credential)
    super(source, credential)
  end
 
  def login
    super
    # initialize fields map
  end
 
  def query(params=nil)
    super(params)
  end
  
  def metadata
    super
  end
 
  def sync
    super
  end
 
  def create(create_hash,blob=nil)
    super(create_hash,blob)
  end
 
  def update(update_hash)
    super(update_hash)
  end
 
  def delete(delete_hash)
    super(delete_hash)
  end
 
  def logoff
    super
  end
end

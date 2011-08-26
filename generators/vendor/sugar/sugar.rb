require 'sugarcrm'

# this is patch to fix class name conflicts 
# between Rhoconnect and SugarCRM gem code
module SugarCRM
  class Module
    def registered?
      @session.namespace_const.const_defined? @klass, false
    end
    
    def to_class
      SugarCRM.const_get(@klass, false).new
    end
  end
end

# this is a patch to fix incorrect 'logout' implementation
module SugarCRM; class Connection
  RESPONSE_IS_NOT_JSON << :logout
  # Logs out of the Sugar user session.
  def logout
    login! unless logged_in?
    json = <<-EOF
      {
          "session": "#{@sugar_session_id}"
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:logout, json)
  end
end; end
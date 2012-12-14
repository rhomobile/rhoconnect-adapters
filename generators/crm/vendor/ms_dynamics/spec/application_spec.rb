require File.join(File.dirname(__FILE__),'spec_helper')

describe "Application" do
  it_should_behave_like "SpecHelper" do
    def should_be_between(t,start,stop)
      dt = DateTime.parse(t)
      dt.should > DateTime.parse(start.to_s)
      dt.should <= DateTime.parse(stop.to_s)
    end
    
    it "should authenticate" do 
      auth_info = RhoconnectAdapters::CRM::MsDynamics.load_auth_info(@test_user)
      auth_info.should_not be_nil
      now = DateTime.now
      should_be_between(auth_info['wlid_expires'],now,(now+(60 * 60 * 24)))
      should_be_between(auth_info['crm_ticket_expires'],now,(now+(60 * 60 * 24)))
    end
    
    it "should not authenticate with wrong credentials" do
      Application.should_receive(:warn).once.with('Can\'t authenticate user wrong_user: #<RuntimeError: RhoconnectAdapters::CRM::MsDynamics::WlidService error w/ IssueTicket: Authentication Failure (0x80041034): The specified member name is either invalid or empty.&#xD;>')    
      Application.authenticate('wrong_user','wrong_password',nil).should be_false
    end
  end
end

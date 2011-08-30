require File.join(File.dirname(__FILE__),'spec_helper')

describe "Application" do
  it_should_behave_like "SpecHelper" do
    before(:each) do
      if SugarCRM.sessions.size > 0
        SugarCRM.disconnect!
      end
    end
    
    it "should authenticate" do 
      Application.authenticate(@test_user,@test_password,nil).should be_true
    end
    
    it "should authenticate using RhoCRM.reconnect" do 
      Application.authenticate(@test_user,@test_password,nil).should be_true
      Application.authenticate(@test_user,@test_password,nil).should be_true
    end
    
    it "should not authenticate with wrong credentials" do
      Application.should_receive(:warn).once.with(/Can't authenticate user wrong_user:/)
      Application.authenticate('wrong_user','wrong_password',nil).should be_false
    end
  end
end
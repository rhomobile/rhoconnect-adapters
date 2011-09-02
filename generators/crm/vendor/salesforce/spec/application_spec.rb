require File.join(File.dirname(__FILE__),'spec_helper')

describe "Application" do
  it_should_behave_like "SpecHelper" do
    it "should authenticate" do 
      Application.authenticate(@test_user,@test_password,nil).should be_true
    end
    
    it "should not authenticate with wrong credentials" do
      Application.should_receive(:warn).once.with(/Can't authenticate user wrong_user: 500 Internal Server Error/)
      Application.authenticate('wrong_user','wrong_password',nil).should be_false
    end
  end
end

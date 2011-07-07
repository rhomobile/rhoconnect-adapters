require File.join(File.dirname(__FILE__),'spec_helper')

describe "Application" do
  it_should_behave_like "SpecHelper" do
    it "should authenticate" do 
      Application.authenticate(@test_user,@test_password,nil).should be_true
    end
    
    it "should not authenticate with wrong credentials" do
      Application.should_receive(:warn).once.with(/wrong_user: #<RuntimeError: LOGIN/)
      Application.authenticate('wrong_user','wrong_password',nil).should be_false
    end
  end
end
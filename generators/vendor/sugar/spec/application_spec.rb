require File.join(File.dirname(__FILE__),'spec_helper')

describe "Application" do
  it_should_behave_like "SpecHelper" do
    it "should authenticate" do 
      pending
    end
    
    it "should not authenticate with wrong credentials" do
      pending
    end
  end
end
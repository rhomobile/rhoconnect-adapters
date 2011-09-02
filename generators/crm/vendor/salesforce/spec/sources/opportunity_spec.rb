require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Opportunity" do
  it_should_behave_like "SpecHelper" do
  
    before(:each) do
      sample_data_file = File.join(File.dirname(__FILE__),'..','..','vendor','salesforce','spec_data','Opportunity.yml')
      @sample_data = YAML.load_file(sample_data_file)['Opportunity'] if sample_data_file and File.exist?(sample_data_file)
      setup_test_for Opportunity,@test_user
      Application.authenticate(@test_user, @test_password,"")
    end
  
    before(:each) do
      @ss.adapter.login
    end
  
    after(:each) do
      @ss.adapter.logoff
    end

    it "should process Opportunity query" do
      result = test_query
      puts result.length.inspect
      query_errors.should == {}
    end
  
    it "should process Opportunity create" do
      create_hash = @sample_data
      result = test_create(create_hash)
      puts result.inspect
      create_hash["Id"] = result
      TestHelpers.created_records = { result => create_hash }
      create_errors.should == {}
    end
  
    it "should process Opportunity update" do
      TestHelpers.created_records.each do |key,value|
        value["OpportunityName"] = "Changed Opportunity #{key.to_s}"
      end
      result = test_update(TestHelpers.created_records)
      puts result.inspect
      update_errors.should == {}
    end
  
    it "should process Opportunity delete" do
      result = test_delete(TestHelpers.created_records)
      puts result.inspect
      delete_errors.should == {}
    end
  end
end

require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Lead" do
  it_should_behave_like "SpecHelper" do
  
    before(:each) do
      sample_data_file = File.join(File.dirname(__FILE__),'..','..','vendor','oracle_on_demand','spec_data','Lead.yml')
      @sample_data = YAML.load_file(sample_data_file)['Lead'] if sample_data_file and File.exist?(sample_data_file)
      setup_test_for Lead,@test_user
      Application.authenticate(@test_user, @test_password,"")
    end
  
    before(:each) do
      @ss.adapter.login
    end
  
    after(:each) do
      @ss.adapter.logoff
    end

    it "should process Lead query" do
      result = test_query
      puts result.length.inspect
      query_errors.should == {}
    end
  
    it "should process Lead create" do
      create_hash = @sample_data
      result = test_create(create_hash)
      puts result.inspect
      create_hash['Id'] = result
      @@created_records = { result => create_hash }
      create_errors.should == {}
    end
  
    it "should process Lead update" do
      @@created_records.each do |key,value|
        value["LeadFirstName"] = "Changed Lead #{key.to_s}"
      end
      result = test_update(@@created_records)
      puts result.inspect
      update_errors.should == {}
    end
  
    it "should process Lead delete" do
      result = test_delete(@@created_records)
      puts result.inspect
      delete_errors.should == {}
    end
  end
end

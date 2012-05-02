require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Lead" do
  it_behaves_like "SpecHelper" do
    before(:each) do
      sample_data_file = File.join(File.dirname(__FILE__),'..','..','vendor','ms_dynamics','spec_data','Lead.yml')
      @sample_data = YAML.load_file(sample_data_file)['Lead'] if sample_data_file and File.exist?(sample_data_file)
      setup_test_for Lead,@test_user
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
      create_hash['leadid'] = result
      TestHelpers.created_records = { result => create_hash }
      create_errors.should == {}
    end
  
    it "should process Lead update" do
      TestHelpers.created_records.each do |key,value|
        value['name'] = "Sample Update #{key.to_s}"
      end
      result = test_update(TestHelpers.created_records)
      puts result.inspect
      update_errors.should == {}
    end
  
    it "should process Lead delete" do
      result = test_delete(TestHelpers.created_records)
      puts result.inspect
      delete_errors.should == {}
    end
  end
end
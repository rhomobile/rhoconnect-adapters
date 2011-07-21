require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Account" do
  it_should_behave_like "SpecHelper" do
    before(:each) do
      sample_data_file = File.join(File.dirname(__FILE__),'..','..','vendor','ms_dynamics','spec_data','Account.yml')
      @sample_data = YAML.load_file(sample_data_file)['Account'] if sample_data_file and File.exist?(sample_data_file)
      puts " we are here and #{@test_user}"
      setup_test_for Account,@test_user
    end
  
    before(:each) do
      @ss.adapter.login
    end
  
    after(:each) do
      @ss.adapter.logoff
    end

    it "should process Account query" do
      result = test_query
      puts result.length.inspect
      query_errors.should == {}
    end
  
    it "should process Account create" do
      create_hash = @sample_data
      result = test_create(create_hash)
      puts result.inspect
      create_hash['accountid'] = result
      TestHelpers.created_records = { result => create_hash }
      create_errors.should == {}
    end
  
    it "should process Account update" do
      TestHelpers.created_records.each do |key,value|
        value['name'] = "Sample Update #{key.to_s}"
      end
      result = test_update(TestHelpers.created_records)
      puts result.inspect
      update_errors.should == {}
    end
  
    it "should process Account delete" do
      result = test_delete(TestHelpers.created_records)
      puts result.inspect
      delete_errors.should == {}
    end
  end
end
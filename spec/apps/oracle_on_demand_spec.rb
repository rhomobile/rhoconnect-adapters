require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "OracleOnDemand App RUNNER" do
  appname = "mynewapp"
  backend = 'OracleOnDemand'
  
  after(:all) do
    FileUtils.rm_rf("/tmp/#{appname}")
  end
  
  it "should run all the specs for standard #{backend} app " do
    RhoconnectAdapters::CRM::TestHelpers.load_templater(backend)
    @app_generator = RhoconnectAdapters::CRM::TestHelpers.generate_sample_app('/tmp',{},appname,backend)
    cmdline = "cd /tmp/#{appname}; rake rhoconnect:spec"
    res = system "#{cmdline}"
    res.should == true
  end
end 

  
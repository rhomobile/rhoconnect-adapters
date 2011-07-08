require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "MsDynamics App RUNNER" do
  appname = "mynewapp"
  backend = 'MsDynamics'
  
  after(:all) do
    FileUtils.rm_rf("/tmp/#{appname}")
  end
  
  it "should run all the specs for standard #{backend} app " do
    load_templater(backend)
    @app_generator = generate_sample_app('/tmp',{:bare => true},appname,backend)
    cmdline = "cd /tmp/#{appname}; rake rhosync:spec"
    res = system "#{cmdline}"
    res.should == true
  end
end 


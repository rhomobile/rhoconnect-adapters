require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','generator','generator_spec_helper')

require 'rhocrm'
require File.join(File.dirname(__FILE__),'..','..','generators','rhocrm')

describe "MsDynamics App RUNNER" do
  appname = "mynewapp"
  backend = 'MsDynamics'
  
  it "should run all the specs for standard #{backend} app " do
    load_templater(backend)
    @app_generator = generate_sample_app('/tmp',{},appname,backend)
    cmdline = "cd /tmp/#{appname}; rake rhosync:spec"
    res = system "#{cmdline}"
    res.should == true
  end
end 


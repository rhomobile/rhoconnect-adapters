require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "Generator" do
  appname = 'mynewapp'
  source = 'CustomObj'
  
  before(:each) do
    FileUtils.mkdir_p '/tmp'
  end
  
  after(:all) do
    FileUtils.rm_rf("/tmp/#{appname}")
  end
  
  describe "AppGenerator Command-line" do
    it "should complain if no name is specified" do
      lambda {
        Rhocrm::AppGenerator.new('/tmp',{})
      }.should raise_error(Templater::TooFewArgumentsError)
    end
    
    it "should complain if no CRM backend is specified" do
      lambda {
        Rhocrm::AppGenerator.new('/tmp',{},appname)
      }.should raise_error(Templater::TooFewArgumentsError)
    end
    
    it "should complain if CRM backend is not valid" do
      lambda {
        Rhocrm::AppGenerator.new('/tmp',{},appname,"foo")
      }.should raise_error(Rhocrm::NotSupportedBackendError)
    end
  end
     
  Rhocrm.registered_backends.each do |backend|      
    describe "Bare #{backend} App Generator" do
      before(:all) do
        Rhocrm::TestHelpers.load_templater(backend)
        @generator = Rhocrm::TestHelpers.generate_sample_app('/tmp',{:bare => true},appname,backend)
      end
        
      it "should not generate any sources with --bare option for #{backend}" do
        SecureRandom.should_receive(:hex).with(64).any_number_of_times
        Rhocrm.standard_sources.each do |source|
          source_name = Rhoconnect.under_score(source)
          @generator.should_not create("/tmp/#{appname}/sources/#{source}.rb")
        end
      end
    end
       
    describe "Default #{backend} App Generator" do 
      before(:all) do
        Rhocrm::TestHelpers.load_templater(backend)
        @generator = Rhocrm::TestHelpers.generate_sample_app('/tmp',{},appname,backend)
      end
        
      it "should create new #{backend} standard application files" do
        SecureRandom.should_receive(:hex).with(64).any_number_of_times
        [ 
          'application.rb',
          "vendor/#{Rhoconnect.under_score(backend)}/application.rb",
          "vendor/#{Rhoconnect.under_score(backend)}/adapter.rb",
          'spec/spec_helper.rb'
          ].each do |template|
            @generator.should create("/tmp/#{appname}/#{template}")
          end
      end
            
      it "should generate standard #{Rhocrm.standard_sources.inspect} sources by default for #{backend}" do
        SecureRandom.should_receive(:hex).with(64).any_number_of_times
        Rhocrm.standard_sources.each do |source|
          source_name = Rhoconnect.under_score(source)
          File.should be_exist("/tmp/#{appname}/sources/#{source_name}.rb")
        end
      end
    end
  end
  
  describe "SourceGenerator Command-Line" do
    it "should complain if no name is specified" do
      lambda {
        Rhocrm::SourceGenerator.new('/tmp',{})
      }.should raise_error(Templater::TooFewArgumentsError)
    end
    
    it "should complain if no CRM backend is specified" do
      lambda {
        Rhocrm::SourceGenerator.new('/tmp',{},source)
      }.should raise_error(Templater::TooFewArgumentsError)
    end
    
    it "should complain if CRM backend is not valid" do
      lambda {
        Rhocrm::SourceGenerator.new('/tmp',{},source,"foo")
      }.should raise_error(Rhocrm::NotSupportedBackendError)
    end
  end
  
  Rhocrm.registered_backends.each do |backend|     
    describe "#{backend} Source Generator" do
      before(:each) do
        Rhocrm::TestHelpers.load_templater(backend)
        @app_generator = Rhocrm::TestHelpers.generate_sample_app('/tmp',{:bare => true},appname,backend)
        @generator = Rhocrm::SourceGenerator.new("/tmp/#{appname}",{},source,backend)
      end
        
      it "should create new source adapter and spec" do
        @generator.should create("/tmp/#{appname}/sources/#{Rhoconnect.under_score(source)}.rb")
        @generator.should create("/tmp/#{appname}/spec/sources/#{Rhoconnect.under_score(source)}_spec.rb")
      end
    end
  end
end

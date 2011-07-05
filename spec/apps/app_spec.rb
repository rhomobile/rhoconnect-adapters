require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'..','generator','generator_spec_helper')

require 'rspec/core/rake_task'

require 'rhocrm'
require File.join(File.dirname(__FILE__),'..','..','generators','rhocrm')

#desc "Run all specs"

describe "App Spec Tester" do
  appname = 'mynewapp'
#  @backend = 'OracleOnDemand'
  backend = 'OracleOnDemand'
  
#  before(:all) do
    load_templater(backend)
    @app_generator = generate_sample_app('/tmp',{},appname,backend)
#  end
  #before(:all) do
#    FileUtils.mkdir_p '/tmp'
#    FileUtils.rm_rf "/tmp/#{appname}"
#    include Rhocrm
#    Dir[File.join(File.dirname(__FILE__),'..','..','generators','vendor',"#{Rhosync.under_score(backend)}",'templates.rb')].each { |vendor_templates| load vendor_templates }
#    @app_generator = Rhocrm::AppGenerator.new('/tmp',{},appname,"OracleOnDemand")
#    @app_generator.invoke!
#    @app_generator.after_run
  #end

  desc "Run apps specs"
  #system('which ruby; cd /tmp; rm -rf mynewapp; rhocrm app mynewapp OracleOnDemand; cd /tmp/mynewapp')
  describe "AppSpecRunner" do
    #it "should execute all #{@backend} specs" do
      puts " we are here in run 0 "
      cmdline = [
            '-X',
            '/tmp/mynewapp',
            '-b',
            '-c',
            '-fd',
            ['/tmp/mynewapp/spec/application_spec.rb']
#        '/tmp/mynewapp/spec/sources/account_spec.rb']
      ]
  #cmdline = "-S bundle exec rspec -b -c -fd /tmp/mynewapp/spec/application_spec.rb /tmp/mynewapp/spec/sources/account_spec.rb"
      #RSpec::Core::Runner.disable_autorun!
      RSpec::Core::Runner.run(cmdline, STDERR, STDOUT)
      #RSpec::configuration.files_to_run.delete('spec/apps/app_spec.rb')
      #RSpec::world.configuration.files_to_run.delete('spec/apps/app_spec.rb')
      #puts " files are : " + RSpec::configuration.files_to_run.inspect
      # = ['/tmp/mynewapp2/spec/application_spec.rb']
      #cmd1 = RSpec::Core::CommandLine.new(cmdline, RSpec::Core::Configuration.new, RSpec::world).run(STDERR, STDOUT)
      #puts " we are here in run cmd1 : "  + cmd1.
    #end
    puts " we are in cmd 1"
  end
  #system('which ruby; cd /tmp; rm -rf mynewapp; rhocrm app mynewapp OracleOnDemand; cd /tmp/mynewapp; bundle install; rake rhosync:spec --trace')
  
#    t.rspec_opts = ["-b", "-c", "-fd"]
#    t.pattern = "/tmp/#{appname}/spec/**/*_spec.rb"
#  end
end


  
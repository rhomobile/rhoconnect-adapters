shared_examples_for "SpecHelper" do
  before(:all) do
    settings = Application.get_settings
    @test_user = settings[:user]
    @test_password = settings[:password]
    puts "Specify test user before running these specs" unless @test_user.length > 0
    puts "Specify test user password before running these specs" unless @test_password.length > 0
  end    
end
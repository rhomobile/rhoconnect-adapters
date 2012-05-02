require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "<%=class_name%>" do
  it_behaves_like "SpecHelper" do
    before(:each) do
      setup_test_for <%=class_name%>,'testuser'
    end

    it "should process <%=class_name%> query" do
      pending
    end

    it "should process <%=class_name%> create" do
      pending
    end

    it "should process <%=class_name%> update" do
      pending
    end

    it "should process <%=class_name%> delete" do
      pending
    end
  end  
end
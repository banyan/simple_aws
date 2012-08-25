require 'test_helper'
require 'simple_aws/core/request'

describe SimpleAWS::Request do

  before do
    @request = SimpleAWS::Request.new :get, "https://example.com", "/action"
  end

  it "is constructed with a method, host and path" do
    @request.wont_be_nil
  end

  it "builds full URI" do
    @request.uri.must_equal "https://example.com/action"
  end

  it "knows it's HTTP method" do
    @request.method.must_equal :get
  end

  it "ensures path is never an empty string" do
    @request.path = ""
    @request.path.must_equal "/"
  end

  describe "headers" do
    it "allows setting raw request headers" do
      @request.headers["Date"] = "This is a header"
      @request.headers["Date"].must_equal "This is a header"
    end
  end

  describe "parameters" do
    it "can be given parameters to pass in" do
      @request.params["Param1"] = "Value1"
      @request.params["Param2"] = "Value2"

      @request.params.must_equal "Param1" => "Value1", "Param2" => "Value2"
    end
  end

  describe "body" do
    it "can be given raw body text" do
      @request.body = "BODY!"
      @request.body.must_equal "BODY!"
    end
  end

  describe "hashes" do
    it "converts hash params to AWS param names" do
      @request.params["Filter"] = [
        {"Name" => "filter1", "Value" => "value1"},
        {"Name" => "filter2", "Value" => ["value14", "another filter"]}
      ]

      @request.params.must_equal({
        "Filter.1.Name" => "filter1",
        "Filter.1.Value" => "value1",
        "Filter.2.Name" => "filter2",
        "Filter.2.Value.1" => "value14",
        "Filter.2.Value.2" => "another filter"
      })
    end

    it "handles any depth of nesting" do
      # Example of using EC2 AuthorizeSecurityGroupEgress
      @request.params["IpPermissions"] = [
        {"IpProtocol" => "udp", "FromPort" => 211, "ToPort" => 142,
          "Groups" => [{"GroupId" => 28}, {"GroupId" => 14}],
          "IpRanges" => [{"CidrIp" => 998}, {"CidrIp" => 12}]
        }
      ]

      @request.params.must_equal({
        "IpPermissions.1.IpProtocol" => "udp",
        "IpPermissions.1.FromPort" => 211,
        "IpPermissions.1.ToPort" => 142,
        "IpPermissions.1.Groups.1.GroupId" => 28,
        "IpPermissions.1.Groups.2.GroupId" => 14,
        "IpPermissions.1.IpRanges.1.CidrIp" => 998,
        "IpPermissions.1.IpRanges.2.CidrIp" => 12
      })
    end

    it "handles a singular hash properly" do
      @request.params["Filter"] = {"Name" => "filter1", "Value" => "value1"}

      @request.params.must_equal({
        "Filter.Name" => "filter1",
        "Filter.Value" => "value1"
      })
    end
  end

  describe "arrays" do
    it "converts array params to AWS param names" do
      @request.params["Filter"] = ["value1", "value2", "value3"]

      @request.params.must_equal({
        "Filter.1" => "value1",
        "Filter.2" => "value2",
        "Filter.3" => "value3"
      })
    end
  end

  describe "date / time objects" do
    it "converts date objects to ISO8601 format" do
      @request.params["Date"] = Date.parse("2012-02-14")
      @request.params.must_equal({
        "Date" => "2012-02-14"
      })
    end

    it "converts time objects to ISO8601 format" do
      @request.params["Time"] = Time.utc(2012, 04, 16, 10, 30, 25)
      @request.params.must_equal({
        "Time" => "2012-04-16T10:30:25Z"
      })
    end
  end
end

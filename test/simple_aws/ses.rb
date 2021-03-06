require 'test_helper'
require 'simple_aws/ses'

describe SimpleAWS::SES do

  before do
    @api = SimpleAWS::SES.new "key", "secret"
  end

  it "points to the endpoint" do
    @api.uri.must_equal "https://email.us-east-1.amazonaws.com"
  end

  it "works with the current version" do
    @api.version.must_equal "2010-12-01"
  end

  describe "API calls" do

    it "builds and signs calls with Signature Version 3" do
      SimpleAWS::Connection.any_instance.expects(:call).with do |request|
        params = request.params
        params.wont_be_nil

        params["Action"].must_equal "SendEmail"
        request.headers["X-Amzn-Authorization"].wont_be_nil

        true
      end

      obj = SimpleAWS::SES.new "key", "secret"
      obj.send_email
    end

  end
end

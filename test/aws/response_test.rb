require 'test_helper'
require 'aws/response'

describe AWS::Response do

  describe "errors" do

    it "raises if the response is not a success" do
      http_response = stub
      http_response.stubs(:success?).returns(false)
      http_response.stubs(:code).returns(401)
      http_response.stubs(:parsed_response).returns({
        "Response" => {
          "Errors" => {
            "Error" => {"Code" => "AuthFailure",
              "Message" => "Message about failing to authenticate"
        }}}
      })

      error =
        lambda {
          AWS::Response.new http_response
        }.must_raise AWS::UnsuccessfulResponse

      error.code.must_equal 401
      error.error_type.must_equal "AuthFailure"
      error.error_message.must_equal "Message about failing to authenticate"

      error.message.must_equal "AuthFailure (401): Message about failing to authenticate"
    end

  end

  describe "successful response parsing and mapping" do
    before do
      @response_hash = {
        "CommandResponse" => {
          "xmlns" => "some url",
          "requestId" => "1234-Request-Id",
          "volumeId" => "v-12345",
          "domain" => "vpc"
        }
      }

      @http_response = stub
      @http_response.stubs(:success?).returns(true)
      @http_response.stubs(:parsed_response).returns(@response_hash)

      @response = AWS::Response.new @http_response
    end

    it "saves the parsed response" do
      @response.body.must_equal @response_hash
    end

    it "allows querying response body with ruby methods" do
      @response.request_id.must_equal "1234-Request-Id"
      @response.volume_id.must_equal "v-12345"
      @response.domain.must_equal "vpc"

      lambda {
        @response.unknown_key
      }.must_raise NoMethodError
    end

    it "allows accessing the request through Hash format" do
      @response["requestId"].must_equal "1234-Request-Id"
      @response["volumeId"].must_equal "v-12345"
      @response["domain"].must_equal "vpc"
      @response["unknownKey"].must_be_nil
    end

  end

  describe "nested responses and arrays" do
    before do
      @response_hash = {
        "CommandResponse" => {
          "xmlns" => "some url",
          "requestId" => "1234-Request-Id",
          "nothing" => nil,
          "simpleNestedObject" => {
            "name" => "Here's something deeper"
          },
          "singleItemResultsSet" => {
            "item" => {"keyId" => "1234", "domain" => "vpc"},
          },
          "multipleItemsSet" => {
            "item" => [
              {"keyId" => "1234"},
              {"keyId" => "5678"},
              {"keyId" => "9012"}
            ]
          },
          "multipleDepthSet" => {
            "key" => "value",
            "simpleInnerSet" => {
              "item" => {"range" => "14"}
            },
            "complexInnerSet" => {
              "item" => [
                {"range" => "12"},
                {"range" => "274", "deeperSet" => { "item" => {"hiddenItem" => "42"}}}
              ]
            }
          },
          "withMemberSet" => {
            "member" => {"keyId" => "4567"}
          }
        }
      }

      @http_response = stub
      @http_response.stubs(:success?).returns(true)
      @http_response.stubs(:parsed_response).returns(@response_hash)

      @response = AWS::Response.new @http_response
    end

    describe "method calls" do

      it "finds keys who's values are nil" do
        @response.nothing.must_be_nil
      end

      it "allows querying multiple objects deep" do
        @response.simple_nested_object.name.must_equal "Here's something deeper"
      end

      it "allows querying of a result set with one item, squashing 'item'" do
        @response.single_item_results_set.length.must_equal 1
        @response.single_item_results_set.first.key_id.must_equal "1234"
        @response.single_item_results_set.first.domain.must_equal "vpc"
      end

      it "allows enumerating through a result set with lots of items" do
        @response.multiple_items_set.length.must_equal 3
        @response.multiple_items_set[0].key_id.must_equal "1234"
        @response.multiple_items_set[1].key_id.must_equal "5678"
        @response.multiple_items_set[2].key_id.must_equal "9012"
      end

      it "allows diving into a nested result set" do
        @response.multiple_depth_set.simple_inner_set.first.range.must_equal "14"
        @response.multiple_depth_set.complex_inner_set[1].deeper_set[0].hidden_item.must_equal "42"
      end

      it "also squashes the 'member' tag" do
        @response.with_member_set[0].key_id.must_equal "4567"
      end
    end

    describe "hash keys" do

      it "finds keys who's values are nil" do
        @response["nothing"].must_be_nil
      end

      it "allows querying multiple objects deep" do
        @response["simpleNestedObject"]["name"].must_equal "Here's something deeper"
      end

      it "allows querying of a result set with one item, squashing the 'item' tag" do
        @response["singleItemResultsSet"].length.must_equal 1
        @response["singleItemResultsSet"][0]["keyId"].must_equal "1234"
        @response["singleItemResultsSet"][0]["domain"].must_equal "vpc"
      end

      it "allows enumerating through a result set with lots of items" do
        @response["multipleItemsSet"].length.must_equal 3
        @response["multipleItemsSet"][0]["keyId"].must_equal "1234"
        @response["multipleItemsSet"][1]["keyId"].must_equal "5678"
        @response["multipleItemsSet"][2]["keyId"].must_equal "9012"
      end

      it "allows diving into a nested result set" do
        @response["multipleDepthSet"]["simpleInnerSet"][0]["range"].must_equal "14"
        @response["multipleDepthSet"]["complexInnerSet"][1]["deeperSet"][0]["hiddenItem"].must_equal "42"
      end

      it "also squashes the 'member' tag" do
        @response["withMemberSet"][0]["keyId"].must_equal "4567"
      end
    end

  end

end

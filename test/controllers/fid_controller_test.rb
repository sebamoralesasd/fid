require "test_helper"

class FidControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get fid_index_url
    assert_response :success
  end
end

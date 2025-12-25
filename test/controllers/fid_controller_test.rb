require "test_helper"

class FidControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get fid_index_url
    assert_response :success
  end

  test "should get index with page parameter" do
    get fid_index_url(page: 2)
    assert_response :success
  end

  test "should handle invalid page numbers gracefully" do
    get fid_index_url(page: -1)
    assert_response :success

    get fid_index_url(page: 0)
    assert_response :success

    get fid_index_url(page: 9999)
    assert_response :success
  end
end

require "test_helper"

class NewsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get news_index_url
    assert_response :success
  end

  test "should get index with page parameter" do
    get news_index_url(page: 2)
    assert_response :success
  end

  test "should handle invalid page numbers gracefully" do
    get news_index_url(page: -1)
    assert_response :success

    get news_index_url(page: 0)
    assert_response :success

    get news_index_url(page: 9999)
    assert_response :success
  end
end

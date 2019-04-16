require 'test_helper'

class ImgAnalyzerControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get img_analyzer_home_url
    assert_response :success
  end

  test "should get analize" do
    get img_analyzer_analize_url
    assert_response :success
  end

end

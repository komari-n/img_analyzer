require 'test_helper'

class ImgAnalizeControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get img_analize_home_url
    assert_response :success
  end

  test "should get analize" do
    get img_analize_analize_url
    assert_response :success
  end

end

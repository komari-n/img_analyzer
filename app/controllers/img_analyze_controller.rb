class ImgAnalyzeController < ApplicationController
  def home
  end

  # 色解析アクション
  def ajax_analize_color
    if request.xml_http_request?
      # ajaxの場合
      img_analyze = ImgAnalyze.new()
      @results = img_analyze.analize_color(params[:file])
    else
      # ajax以外
      render 'home'
    end
  end

  # 表情解析アクション
  def ajax_analize_face
    if request.xml_http_request?
      # ajaxの場合
      img_analyze = ImgAnalyze.new()
      @results = img_analyze.analize_face(params[:file])
    else
      # ajax以外
      render 'home'
    end
  end

end
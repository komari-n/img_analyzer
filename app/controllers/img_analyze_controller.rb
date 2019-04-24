class ImgAnalyzeController < ApplicationController
  def home
  end

  def ajax_analize
    if request.xml_http_request?
      # ajaxの場合
      img_analyze = ImgAnalyze.new()
      @results = img_analyze.analize(params[:file], params[:type])
    else
      # ajax以外
      render 'home'
    end
  end

end
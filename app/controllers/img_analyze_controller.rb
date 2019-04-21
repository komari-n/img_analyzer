class ImgAnalyzeController < ApplicationController
  def home
  end

  def ajax_analize
    if request.xml_http_request?
      # ajaxの場合
      img_analyze = ImgAnalyze.new()
      @results = img_analyze.analize(params[:file], params[:type])
      # TODO: [2]エラー処理 そもそもこのif文はいらないかも？？
    else
      # ajax以外の場合
    end
  end

end
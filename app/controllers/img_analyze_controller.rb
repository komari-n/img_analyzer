class ImgAnalyzeController < ApplicationController
  def home
  end

  def ajax_analize # TODO: [1]ajaxで処理
    #  Ajax処理
    img_analyze = ImgAnalyze.new()
    @results = img_analyze.analize(params[:file], params[:type])

    render 'home'
  end

end
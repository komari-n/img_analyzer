require "google/cloud/vision"

class ImgAnalyze
    include ActiveModel::Model

    #
    # 画像解析処理
    #
    def analize(file, type)
        # ImageAnnotator インスタンス生成
        image_annotator = Google::Cloud::Vision::ImageAnnotator.new(
            version: :v1,
            credentials: ENV["GOOGLE_APPLICATION_CREDENTIALS"]
        )
        
        base64image = file.read # TODO: [2]画像かhtmlURLか判別して content: source: 分岐させる
        requests_content = format_requests(base64image, type)
        requests = [requests_content]

        # Cloud Vision APIからレスポンスを受け取る
        api_res = image_annotator.batch_annotate_images(requests); # TODO: [1]エラー処理

        # ユーザのリクエストに応じてレスポンス成形
        case type.to_sym
        when :IMAGE
            # 色解析レスポンス成形
            # total_score = nil # スコアの合計値
            # score = nil # スコアの割合
            # rgb = nil # rgb値
            # ret_items = [total_score: total_score, {rgb: rgb, score: score}, {}, {}]
            total_score = 0
            responses = []
            colors    = api_res.responses[0].
                        image_properties_annotation.dominant_colors.colors
            
            colors.each do |i|
                items = i.to_h
                items[:color].delete(:alpha)

                # rgb(123.0, 45.0, 89.0)rgb(123, 45, 89)みたいに成形
                # スコアは小数点2位を四捨五入
                rgb   = "rgb(#{items[:color].values.join(", ")})".gsub('.0', '')
                # TODO[2]: 丸まらない場合がある float * 100 をしているから？ bigDecimal使う
                score = (items[:score] * 100).round(1)

                responses << {rgb: rgb, score: score}
                total_score += score
            end

            # TODO: [1]トータルスコアに対する各スコアの割合 rgbはintじゃないと？ スコア丸め
            responses.each_with_index do |view_item, idx|
                # BigDecimalで計算
                dec_score = "#{view_item[:score]}".to_d
                dec_total = "#{total_score}".to_d

                # TODO: [2]パーセンテージの誤差をどう埋めるか？ 100 とpct合計値を比較して差を算出
                # 差がある場合は 切り捨てた数値が一番大きい色のパーセンテージにプラスする
                # 差が0.1の場合と0.2の場合があったりする？→誤差率の算出方法？
                percentage = ( ( dec_score.div( dec_total, 4 ) ).to_f * 100 )
                # パーセンテージは小数点2位を四捨五入 整数で表せる値も小数のままにしておく
                responses[idx][:percentage] = percentage.round(1)
            end

            # トータルスコアを先頭に追加して返却
            return responses.unshift( total_score: total_score )
        when :CROP
            # TODO: [3]クロップヒントレスポ成形処理
        else
            # TODO: [2]●●●_DETECTIONレスポ成形処理
        end
    end

    # 
    # リクエストコンテンツ作成
    #
    def format_requests(image, type)
        # caseはスコープを作らない
        case type.to_sym
        when :IMAGE
            detection_type = { type: :IMAGE_PROPERTIES }
        when :CROP
            detection_type = { type: :CROP_HINTS }
        else # reatureが●●●_DETECTIONのもの
            detection_type = { type: "#{type}_DETECTION".to_sym}
        end
        
        # TODO: [2]htmlURLが渡された場合は image:{source: {"htmlURL"}}にする
        contents = { image: { content: image }, features: [detection_type] }
    end

end

########################### リクエスト参考
#     contents = {
#         image: {
#             content: image,                       # base64形式の画像
#             source: {"htmlURL"}                   # 処理追加 ※contentと両方セットされている場合はcontent優先
#         },
#         features: [
#             { type: :LABEL_DETECTION },           # 画像のカテゴリを判定
#             { type: :TEXT_DETECTION },            # テキスト抽出(画像向け)
#             { type: :DOCUMENT_TEXT_DETECTION },   # テキスト抽出(文章向け)
#             { type: :SAFE_SEARCH_DETECTION  },    # セーフサーチ
#             { type: :FACE_DETECTION },            # 顔のパーツ、感情判定
#             { type: :LANDMARK_DETECTION },        # ランドマーク判定
#             { type: :LOGO_DETECTION },            # 一般手的な商品や企業ロゴを判定
#             { type: :IMAGE_PROPERTIES },          # 画像のRPG値と割合パーセンテージを判定
#             { type: :WEB_DETECTION },             # 相関が高い画像をweb検索
#             { type: :CROP_HINTS },                # 主要な物体別に座標を判定 トリミングで分割できる
#         ],
#         imageContext: {
#             # 必要ないかも
#             webDetectionParams: {
#                 includeGeoResult: "boolean"       # 地理情報から派生した結果を含めるかどうか
#             }
#         }
#     }
###########################
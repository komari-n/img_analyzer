require "google/cloud/vision"

class ImgAnalyze
    include ActiveModel::Model

    #
    # 画像解析処理
    #
    def analize(file, type)
        ret_response = {err_msg: [], color_items: []}

        # サイズチェック
        if file.size > 4.megabyte
            mb = ApplicationController.helpers.number_to_human_size(file.size)
            ret_response[:err_msg] << "ファイルサイズは4MB以内のものを選択してください。[選択画像: #{mb}]"
        end
        # バイナリチェック
        result_msg = check_binaly_file(file)
        if result_msg.length != 0
            ret_response[:err_msg] += result_msg
        end
        # API呼出前のエラーはまとめて返却
        return ret_response unless ret_response[:err_msg].empty?
        
        # ImageAnnotator インスタンス生成
        image_annotator = Google::Cloud::Vision::ImageAnnotator.new(
            version: :v1,
            credentials: ENV["GOOGLE_APPLICATION_CREDENTIALS"]
        )
        # APIリクエスト作成
        base64image = file.read # TODO: [2]画像かhtmlURLか判別して content: source: 分岐させる
        requests_content = format_requests(base64image, type)
        requests = [requests_content]

        # Cloud Vision APIからレスポンスを受け取る
        api_res = image_annotator.batch_annotate_images(requests)
        # APIエラー
        api_err = api_res.responses[0].error.to_h
        if api_err.length != 0
            ret_response[:err_msg] << "APIエラーが発生しました。 [ message: #{api_err[:message]} code: #{api_err[:code]} ]"
            return ret_response
        end

        # ユーザのリクエストに応じてレスポンス成形
        case type.to_sym
        when :IMAGE
            colors    = api_res.responses[0].
                        image_properties_annotation.dominant_colors.colors
            
            ret_response[:color_items] = format_response_image(colors)
        when :CROP
            # TODO: [3]クロップヒントレスポ成形処理
        else
            # TODO: [2]●●●_DETECTIONレスポ成形処理
        end

        return ret_response
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

    #
    # 色解析レスポンス成形
    #
    def format_response_image(colors)
        total_score = 0
        responses = []
        
        # apiレスポンスから必要なデータを抽出
        colors.each do |i|
            items = i.to_h
            items[:color].delete(:alpha)

            # 小数点2位を四捨五入
            rgb   = "rgb(#{items[:color].values.join(", ")})".gsub('.0', '')
            score = (items[:score] * 100).round(1)

            responses << {rgb: rgb, score: score}
            total_score += score
        end
        # 小数点2位を四捨五入
        total_score = total_score.round(1)

        # トータルスコア / 各スコアのパーセンテージを計算
        responses.each_with_index do |view_item, idx|
            dec_score = "#{view_item[:score]}".to_d
            dec_total = "#{total_score}".to_d
            percentage = ( ( dec_score.div( dec_total, 4 ) ).to_f * 100 )
            # パーセンテージは小数点2位を四捨五入
            responses[idx][:percentage] = percentage.round(1)
        end

        # トータルスコアを先頭に追加
        responses.unshift( total_score: total_score )
    end

    #
    # バイナリファイルチェック
    #
    def check_binaly_file(file)
        err_msg = []

        File.open(file.path, 'rb') do |f|
            begin
                # 引数を指定してバイナリを読み込み
                header = f.read(8)
                f.seek(-12, IO::SEEK_END)
                footer = f.read(12)
            rescue
                err_msg << '画像を読み込めませんでした。別の画像を選択してください。'
            end

            # ファイルフォーマットで中身と拡張子が一致しているか判断
            correct_format = false
            if (header[0, 2].unpack("H*") == ['ffd8']) && (footer[-2, 2].unpack("H*") == ["ffd9"])
                # jpg: SOIマーカーとEOIマーカーを確認
                correct_format = true
            elsif (header[0, 3].unpack("A*") == ["GIF"]) && (footer[-1, 1].unpack("H*") == ["3b"])
                # gif: gifシグネチャとtrailerで判断
                correct_format = true
            elsif (header[0, 8].unpack("H*") == ["89504e470d0a1a0a"]) && (footer[-12, 12].unpack("H*") == ["0000000049454e44ae426082"])
                # png: pngファイルシグネチャとIENDチャンクで判断
                correct_format = true
            elsif header[0,2].unpack("A*") == ["BM"]
                # bitmap: ファイルタイプで判断
                correct_format = true
            elsif header[0,3].unpack("H*") == ["000001"]
                # icon: icoリソースタイプで判断
                correct_format = true
            end
            err_msg << '拡張子とファイルの中身が一致しませんでした。別の画像を選択してください。' unless correct_format
        end

        return err_msg
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
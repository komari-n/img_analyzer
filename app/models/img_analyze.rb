require "google/cloud/vision"
require "RMagick"

class ImgAnalyze
    include ActiveModel::Model
    include Magick

    #
    # 色解析処理
    #
    def analize_color(file)
        ret_response = {err_msg: nil}

        # バリデーション
        ret_response[:err_msg] = validation(file)
        if ret_response[:err_msg] != nil
            return ret_response
        end

        # apiリクエスト送信
        api_res = send_api_request(file, "IMAGE")
        # APIエラーチェック
        api_err = api_res.responses[0].error.to_h
        if api_err.length != 0
            ret_response[:err_msg] = "APIエラーが発生しました。 [ message: #{api_err[:message]} code: #{api_err[:code]} ]"
            return ret_response
        end

        # レスポンス成形
        colors = api_res.responses[0].
                image_properties_annotation.dominant_colors.colors
        ret_response[:color_items] = format_response_image(colors)

        return ret_response
    end

    #
    # 表情解析処理
    #
    def analize_face(file)
        ret_response = {err_msg: nil, face_anno_items: [annotated_image: "", extraction_targets_info: [] ]}

        # バリデーション
        ret_response[:err_msg] = validation(file)
        if ret_response[:err_msg] != nil
            return ret_response
        end
        
        # apiリクエスト送信
        api_res = send_api_request(file, "FACE")
        # APIエラーチェック
        api_err = api_res.responses[0].error.to_h
        if api_err.length != 0
            ret_response[:err_msg] = "APIエラーが発生しました。 [ message: #{api_err[:message]} code: #{api_err[:code]} ]"
            return ret_response
        end

        # レスポンス生成
        hash_res = api_res.to_h
        face_annotations = hash_res[:responses][0][:face_annotations]
        # TODO: 表情解析できなかった場合
        ret_response[:face_anno_items] = format_response_face(face_annotations, file.path)

        return ret_response
    end

    #
    # Cloud Vision API リクエスト送信
    #
    def send_api_request(file, type)
        # ImageAnnotator インスタンス生成
        image_annotator = Google::Cloud::Vision::ImageAnnotator.new(
            version: :v1,
            credentials: ENV["GOOGLE_APPLICATION_CREDENTIALS"]
        )
        # 本番環境はこっち
        # credentials: credentials: JSON.parse(ENV["GOOGLE_APPLICATION_CREDENTIALS"])

        # リクエスト作成
        blob = file.read # TODO: 画像かhtmlURLか判別して content: source: 分岐させる
        case type.to_sym
        when :IMAGE
            detection_type = { type: :IMAGE_PROPERTIES }
        when :CROP
            detection_type = { type: :CROP_HINTS }
        else # reatureが●●●_DETECTIONのもの
            detection_type = { type: "#{type}_DETECTION".to_sym}
        end
        requests_content = { image: { content: blob }, features: [detection_type] }
        requests = [requests_content]

        # リクエスト送信
        image_annotator.batch_annotate_images(requests)
    end

    #
    # 色解析レスポンス成形
    #
    def format_response_image(colors)
        total_score = 0
        response = []
        
        # apiレスポンスから必要なデータを抽出
        colors.each do |i|
            items = i.to_h
            items[:color].delete(:alpha)

            # 小数点2位を四捨五入
            rgb   = "rgb(#{items[:color].values.join(", ")})".gsub('.0', '')
            score = (items[:score] * 100).round(1)

            response << {rgb: rgb, score: score}
            total_score += score
        end
        # 小数点2位を四捨五入
        total_score = total_score.round(1)

        # トータルスコア / 各スコアのパーセンテージを計算
        response.each_with_index do |view_item, idx|
            dec_score = "#{view_item[:score]}".to_d
            dec_total = "#{total_score}".to_d
            percentage = ( ( dec_score.div( dec_total, 4 ) ).to_f * 100 )
            # パーセンテージは小数点2位を四捨五入
            response[idx][:percentage] = percentage.round(1)
        end

        # トータルスコアを先頭に追加
        response.unshift( total_score: total_score )
    end

    #
    # 表情解析レスポンス成形
    #
    def format_response_face(face_annotations, file_path)
        response = []

        extraction_targets_info = []               # 抽出対象ごとの個別情報
        image  = Magick::ImageList.new(file_path)  # ポイント描画用画像
        dr = Draw.new                              # 描画バッファ

        # 描画バッファの設定
        dr.fill('none')
        dr.stroke = "#20F010 "
        dr.stroke_width(6)
        dr.font_size(20)

        face_annotations.each_with_index do |face_annotation, idx|
            # 描画バッファにポイントを追加
            buffer_points(dr, face_annotation)
            # 顔を複数検出していた場合は番号を振る
            if face_annotations.size > 1
                bounding_poly = face_annotation[:bounding_poly][:vertices]
                x = bounding_poly[0][:x] + 20
                y = bounding_poly[0][:y] + 15
                # 文字用に設定
                dr.fill('#20F010')
                dr.stroke_width(1)
                dr.font_size(16)
                dr.font_weight(200)
                # 文字を描画
                dr.text(x, y, "face" + (idx + 1).to_s)
                # ポイント用に再設定
                dr.fill('none')
                dr.stroke_width(6)
                dr.font_size(20)
                dr.font_weight(400)
            end

            # 抽出対象ごとの個別情報を取得
            extraction_target_info = format_face_extraction_target_info(face_annotation)
            extraction_targets_info << extraction_target_info
        end

         # ポイント描画用画像に描画バッファを出力
         dr.draw(image)
         # base64形式に変換
         annotated_image = Base64.strict_encode64(image.to_blob)
         annotated_image_url = "data:image/jpeg;base64," + annotated_image

        response = [
            annotated_image_url: annotated_image_url,
            extraction_targets_info: extraction_targets_info
        ]
    end

    #
    # 描画バッファにポイントを追加
    #
    def buffer_points(dr, face_annotation)
        # 矩形
        bounding_poly = face_annotation[:bounding_poly][:vertices]
        fd_bounding_poly = face_annotation[:fd_bounding_poly][:vertices]
        # 特徴点
        annotations = []
        face_annotation[:landmarks].each do |item|
            # 小数点以下切り捨て
            x = item[:position][:x].to_i
            y = item[:position][:y].to_i
            annotations << { x: x, y: y }
        end

         # 矩形をdraw領域に描画
        dr.polyline(bounding_poly[0][:x], bounding_poly[0][:y],
            bounding_poly[1][:x], bounding_poly[1][:y],
            bounding_poly[2][:x], bounding_poly[2][:y],
            bounding_poly[3][:x], bounding_poly[3][:y],
            bounding_poly[0][:x], bounding_poly[0][:y])
        dr.polyline(fd_bounding_poly[0][:x], fd_bounding_poly[0][:y],
                    fd_bounding_poly[1][:x], fd_bounding_poly[1][:y],
                    fd_bounding_poly[2][:x], fd_bounding_poly[2][:y],
                    fd_bounding_poly[3][:x], fd_bounding_poly[3][:y],
                    fd_bounding_poly[0][:x], fd_bounding_poly[0][:y])

         # ポイントをdraw領域に描画
        annotations.each do |points|
            dr.text((points[:x]-3), (points[:y]+5), "-")
        end
    end

    #
    # 抽出対象ごとの個別情報(顔解析)を成形
    #
    def format_face_extraction_target_info(face_annotation)
        extraction_target_info = {}

        # 角度
        roll_angle = face_annotation[:roll_angle].to_i # ロール角(顔の傾き)
        tilt_angle = face_annotation[:tilt_angle].to_i # ピッチ角(顔の上下)
        pan_angle = face_annotation[:detection_confidence].to_i # ヨー角(顔の左右)

        # 解析結果の信頼性 TODO 計算方法怪しい
        detection_confidence = "#{face_annotation[:detection_confidence]}".to_d * 100
        detection_confidence = detection_confidence.to_f.round(1)

        # 感情予測
        likelihoods = face_annotation.select {|key, value| key.to_s.match(/_likelihood/)}
        ret_likelihoods = {}
        # 返却値作成
        likelihoods.each do |key, value|
            # viewに直接出力できるようキーを短縮
            short_key = key.to_s.sub!(/_likelihood/, "").to_sym

            # 6つの予測値を数値に変換
            case value
            when :UNKNOWN
                ret_likelihoods[short_key] = 0
            when :VERY_UNLIKELY
                ret_likelihoods[short_key] = 1
            when :UNLIKELY
                ret_likelihoods[short_key] = 2
            when :POSSIBLE
                ret_likelihoods[short_key] = 3
            when :LIKELY
                ret_likelihoods[short_key] = 4
            when :VERY_LIKELY
                ret_likelihoods[short_key] = 5
            end
        end

        extraction_target_info = {
            detection_confidence: detection_confidence,
            roll_angle: roll_angle,
            tilt_angle: tilt_angle,
            pan_angle: pan_angle,
            likelihoods: ret_likelihoods
        }
    end

    #
    # バリデーション
    #
    def validation(file)
        # ファイル存在チェック
        if file == nil
            return "ファイルを選択してください。"
        end
        # サイズチェック
        if file.size > 4.megabyte
            mb = ApplicationController.helpers.number_to_human_size(file.size)
            return "ファイルサイズは4MB以内のものを選択してください。[選択画像: #{mb}]"
        end
        # バイナリチェック
        result_msg = check_binaly_file(file)
        if result_msg != nil
            return result_msg
        end
    end

    #
    # バイナリファイルチェック
    #
    def check_binaly_file(file)

        File.open(file.path, 'rb') do |f|
            begin
                # 引数を指定してバイナリを読み込み
                header = f.read(8)
                f.seek(-12, IO::SEEK_END)
                footer = f.read(12)
            rescue
                return '画像を読み込めませんでした。別の画像を選択してください。'
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

            unless correct_format
                return '拡張子とファイルの中身が一致しませんでした。別の画像を選択してください。'
            end
        end
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
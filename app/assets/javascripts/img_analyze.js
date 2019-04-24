$(function() {
  /**
   * ---------- イベントリスナー ----------
   */
  // 解析ボタン
  var anaBtn = $(".ana_btn");
  anaBtn.on("click", onClickAnaBtn);

  // ドロップ領域
  var dropArea = $("#drop_area");
  var fileInput = $("#file_input");
  dropArea
    .on("dragover", onDragOver)
    .on("dragleave", onDragLeave)
    .on("drop", onDrop)
    .on("click", onClickDropArea);

  // ファイル参照ボタン
  fileInput.on("change", onChangeFileInput).on("click", onClickFileInput);

  // 入力form
  var analize = $("#analize");
  analize.on("ajax:complete", ajaxComplete);

  /**
   * ---------- イベントリスナー コールバック ----------
   */

  // 解析ボタン クリック
  function onClickAnaBtn() {
    $("#ana_type").val(anaBtn.attr("name"));
    $(".load_screen").css("display", "flex");
  }

  // ドロップ領域 ドラッグオーバー
  function onDragOver(e) {
    e.preventDefault();

    // 許可しないファイルならエフェクトは変わらない
    var mimeType = e.originalEvent.dataTransfer.items[0]["type"];
    if (isCorrectMimeType(mimeType) == true) {
      addEnterEffect();
    }
  }

  // ドロップ領域 ドラッグリーブ
  function onDragLeave(e) {
    e.preventDefault();
    removeEnterEffect();
  }
  // ドロップ領域 ドロップ
  function onDrop(e) {
    e.preventDefault();
    removeEnterEffect();
    var dataTransfer = e.originalEvent.dataTransfer;

    // MIMEタイプをチェック
    var mimeType = dataTransfer.items[0]["type"];
    if (isCorrectMimeType(mimeType) != true) {
      // TODO: [*]こっちは見た目で分かるようになってると思う…。
      return;
    }
    // ドロップしたファイル数をチェック
    if (isSingleFile(dataTransfer.files) != true) {
      // TODO: [*]エラーメッセージを出したほうがいいかも？
      return;
    }
    // エラーメッセージをチェック
    if (isExistErrMessage() == true) {
      $(".msg_area").empty();
      $(".msg_area").css("display", "none");
    }

    // 解析結果を初期化
    $(".result_area").empty();
    // 選択ファイルが1つなら画像成形
    var files = dataTransfer.files;
    organizeFiles(files);

    // TODO: [2]ローカル画像ファイル htmlURL 画面内画像 の場合分け
    // TODO: [2]htmlURLの場合  クロスドメイン引っかかる railsでリクエスト JSONPでリクエスト
    // TODO: [3]画面内画像の場合
  }
  // ドロップ領域 クリック
  function onClickDropArea() {
    // もしクリックしたらファイル選択表示
    fileInput.click();
  }

  // ファイル参照ボタン チェンジ
  function onChangeFileInput(e) {
    // 前回入力値を初期化
    $("#target_img").attr("src", "");
    $(".result_area").empty();

    // エラーメッセージをチェック
    if (isExistErrMessage() == true) {
      $(".msg_area").empty();
      $(".msg_area").css("display", "none");
    }

    // ファイルが選択された場合のみ画像成形
    var files = e.originalEvent.target.files;
    if (isExistFiles(files) == true) {
      // 参照ボタンからだと複数選択できないのでファイル数チェックはなし
      organizeFiles(files);
    }
  }
  // ファイル参照ボタン クリック
  function onClickFileInput(e) {
    // 無限ループ(ドロップ領域クリック時)・バブリング防止
    e.stopPropagation();
  }

  // 入力form ajaxリクエスト完了
  function ajaxComplete() {
    $(".load_screen").fadeOut(1200);
  }

  /**
   * ---------- ロジックメソッド ----------
   */

  // ドロップ領域のエフェクト制御
  var dropAreaWrap = $("#drop_area_wrap");
  function addEnterEffect() {
    dropAreaWrap.addClass("drag_enter");
  }
  function removeEnterEffect() {
    dropAreaWrap.removeClass("drag_enter");
  }

  // 画像成形処理
  function organizeFiles(files) {
    var image = $("#target_img");
    var blobURL = URL.createObjectURL(files[0]); // 存在チェックはされてる前提…。

    // input type='file"要素にファイルを設定
    fileInput.get(0).files = files;
    // 表示領域にバイナリURL設定
    image.attr("src", blobURL);

    // 画像読み込み完了後 バイナリURL破棄
    $(image).on("load", function() {
      URL.revokeObjectURL(blobURL);
    });
  }

  /**
   * ---------- バリデーション ----------
   */

  // ファイルMIMEタイプチェック
  function isCorrectMimeType(mimeType) {
    // MIMEタイプが共通で取れたのでMIMEタイプでチェック
    var match = mimeType
      .toLowerCase()
      .match(/\/(jpeg|png|gif|bmp|x-icon|vnd.microsoft.icon)$/i);
    if (match != null) {
      return true;
    }
    return false;
  }

  // ファイル存在チェック
  function isExistFiles(files) {
    if (files.length >= 1) {
      return true;
    }
    return false;
  }

  // ファイル数チェック
  function isSingleFile(files) {
    if (files.length == 1) {
      return true;
    }
    return false;
  }

  // エラーメッセージチェック
  function isExistErrMessage() {
    if ($(".msg_text").length) {
      return true;
    }
    return false;
  }

  /**
   * ---------- 画面共通 ----------
   */

  // 指定領域以外はファイルドロップ禁止
  window.addEventListener(
    "dragover",
    function(e) {
      e.preventDefault();
    },
    false
  );
  window.addEventListener(
    "drop",
    function(e) {
      e.preventDefault();
      e.stopPropagation();
    },
    false
  );
});

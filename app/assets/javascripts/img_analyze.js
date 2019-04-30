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

  // 入力フォーム
  var analize_form = $("#analize_form");
  analize_form.on("ajax:complete", ajaxComplete);

  /**
   * ---------- イベントリスナー コールバック ----------
   */

  // 解析ボタン クリック
  function onClickAnaBtn() {
    // アクション先を指定
    $("#analize_form").attr("action", $(this).data("action"));

    // ロード画面を表示
    $(".load_screen").css("display", "flex");

    if (anaBtn.attr("form") != "analize_form") {
      $(".load_screen").css("display", "none");
    }
  }

  // ドロップ領域 ドラッグオーバー
  function onDragOver(e) {
    e.preventDefault();

    // 許可したファイルの場合のみエフェクト反応
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
      return;
    }
    // ドロップしたファイル数をチェック
    if (isSingleFile(dataTransfer.files) != true) {
      return;
    }

    // 画面表示を初期化
    displayRefresh();

    // ドロップ画像表示
    var files = dataTransfer.files;
    setImageSrc(files);
  }

  // ドロップ領域 クリック
  function onClickDropArea() {
    // ファイル選択表示
    fileInput.click();
  }

  // ファイル参照ボタン チェンジ
  function onChangeFileInput(e) {
    // 画面表示を初期化
    displayRefresh();

    var files = e.originalEvent.target.files;
    if (isExistFiles(files)) {
      // 画像表示
      setImageSrc(files);
    } else {
      // ファイルを選択しなければ表示画像は消す
      $("#target_img").attr("src", "");
    }
  }

  // ファイル参照ボタン クリック
  function onClickFileInput(e) {
    // 無限ループ(ドロップ領域クリック時)・バブリング防止
    e.stopPropagation();
  }

  // 入力フォーム ajaxリクエスト完了
  function ajaxComplete() {
    $(".load_screen").fadeOut(1200);
  }

  /**
   * ---------- ロジック ----------
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
  function setImageSrc(files) {
    var image = $("#target_img");
    var blobURL = URL.createObjectURL(files[0]);

    // input type='file"要素にファイルを設定
    fileInput.get(0).files = files;
    // 表示領域にバイナリURL設定
    image.attr("src", blobURL);

    // 画像読み込み完了後 バイナリURL破棄
    $(image).on("load", function() {
      URL.revokeObjectURL(blobURL);
    });
  }

  // 画面表示リフレッシュ
  function displayRefresh() {
    // エラーメッセージリフレッシュ
    if ($(".msg_text").length) {
      $("msg_area").empty();
      $(".msg_area").css("display", "none");
    }

    // 解析結果リフレッシュ
    if ($(".response_html").length) {
      $(".result_area").empty();
    }
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

  /**
   * ---------- そのた ----------
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

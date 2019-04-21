$(function() {
  // 解析ボタン イベントリスナー
  var anaBtn = $(".ana_btn");
  anaBtn.on("click", function() {
    $("#ana_type").val(anaBtn.attr("name"));
  });

  // ドロップ領域 イベントリスナー
  var dropArea = $("#drop_area");
  var fileInput = $("#file_input");
  dropArea
    .on("dragover", onDragOver)
    .on("dragleave", onDragLeave)
    .on("drop", onDrop)
    .on("click", function() {
      fileInput.click();
    });

  // ファイル参照ボタン イベントリスナー
  fileInput
    .on("change", function(e) {
      organizeFiles(e.originalEvent.target.files);
    })
    .on("click", function(e) {
      // バブリング防止
      e.stopPropagation();
    });

  function onDragOver(e) {
    e.preventDefault();
    addEnterEffect();
  }

  function onDragLeave(e) {
    e.preventDefault();
    removeEnterEffect();
  }

  function onDrop(e) {
    e.preventDefault();
    removeEnterEffect();

    var dataTransfer = e.originalEvent.dataTransfer;
    // ローカル画像ファイルの場合
    organizeFiles(dataTransfer.files);
    // TODO: [2]htmlURLの場合  クロスドメイン引っかかる railsでリクエスト JSONPでリクエスト
    // TODO: [3]画面内画像の場合
  }

  // ドロップ領域の表示制御
  var dropAreaWrap = $("#drop_area_wrap");
  function addEnterEffect() {
    dropAreaWrap.addClass("drag_enter");
  }
  function removeEnterEffect() {
    dropAreaWrap.removeClass("drag_enter");
  }

  // 画像成型 TODO [*]何か違う
  function organizeFiles(files) {
    // ファイルinputに設定
    var domFileInput = fileInput.get(0);
    domFileInput.files = files;
    // 画面出力 TODO: [2]FileListになっている for文 バリデーション size1より大きいと嫌
    outputImage(files[0]);
  }

  // 画像出力
  function outputImage(file) {
    var image = $("#target_img");
    var blobURL = URL.createObjectURL(file);

    // 表示領域にバイナリURL設定
    image.attr("src", blobURL);
    // 画像読み込み完了後 バイナリURL破棄
    $(image).on("load", function() {
      URL.revokeObjectURL(blobURL);
    });
  }
});

/**
 * VideoPlayer.pde
 * 負責教學影片播放管理、結束偵測與結算提示繪製
 */

Movie currentMovie;
boolean isVideoFinished = false;
String currentVideoName = "";

/**
 * 啟動影片播放
 */
void startVideo(String videoPath) {
  // 安全釋放上一次的影片
  if (currentMovie != null) {
    currentMovie.stop();
    currentMovie = null;
  }
  
  currentVideoName = videoPath;
  isVideoFinished = false;
  
  // 建立影片物件並播放
  currentMovie = new Movie(this, videoPath);
  currentMovie.play();
}

/**
 * 繪製影片播放與結束畫面
 */
void drawVideoScreen() {
  pushStyle();
  background(15, 15, 25); // 暗藍色背景

  if (currentMovie == null) {
    popStyle();
    return;
  }

  // 1. 偵測影片是否播放完畢
  // 當前時間 >= 總長度 - 0.2 秒 (保留微小緩衝區防止浮點數不精準導致無法觸發)
  if (!isVideoFinished && currentMovie.time() >= currentMovie.duration() - 0.2) {
    isVideoFinished = true;
    currentMovie.pause(); // 播完後定格並切換狀態
  }

  // 2. 根據播放狀態繪製視覺
  if (!isVideoFinished) {
    // ---------------------------------------------------------
    // 狀態 A：影片正在播放中 (全螢幕等比例縮放繪製)
    // ---------------------------------------------------------
    imageMode(CORNER);
    image(currentMovie, 0, 0, width, height);
    
    // 底部半透明進度條提示
    noStroke();
    fill(0, 0, 0, 100);
    rect(0, height - 25, width, 25);
    
    float progress = currentMovie.time() / currentMovie.duration();
    fill(ACCENT_CYAN);
    rect(0, height - 6, width * progress, 6);
    
    fill(200);
    textSize(12);
    textAlign(LEFT, CENTER);
    text("正在播放: " + currentVideoName + " (可按 [R] 鍵強制中斷返回)", 20, height - 15);
    
  } else {
    // ---------------------------------------------------------
    // 狀態 B：影片播放完畢 (顯示恭喜與返回按鈕)
    // ---------------------------------------------------------
    fill(OVERLAY_DARK);
    rect(0, 0, width, height);
    
    // 顯示「恭喜成功看完的字」
    textAlign(CENTER, CENTER);
    fill(STATUS_SUCCESS); // 亮綠色
    textSize(46);
    textFont(mainFont);
    text("🎉 恭喜成功看完教學影片！", width/2, height/2 - 60);
    
    fill(TEXT_SECONDARY);
    textSize(22);
    text("您已成功完成「" + getFriendlyVideoName() + "」的視覺觀摩演練。", width/2, height/2 + 10);

    // 繪製「返回教學範例」按鈕
    float btnW = 240;
    float btnH = 55;
    float btnX = width/2 - btnW/2;
    float btnY = height/2 + 80;
    
    boolean isHover = (mouseX >= btnX && mouseX <= btnX + btnW && mouseY >= btnY && mouseY <= btnY + btnH);
    
    if (isHover) {
      fill(ACCENT_CYAN);
      stroke(255);
      strokeWeight(2);
    } else {
      fill(INFO_BLOCK_BG);
      stroke(BORDER_SUBTLE);
      strokeWeight(1.5);
    }
    
    rect(btnX, btnY, btnW, btnH, 12);
    
    if (isHover) fill(30);
    else fill(255);
    
    textSize(22);
    text("返回教學範例", width/2, btnY + btnH/2 - 4);
  }

  popStyle();
}

/**
 * 處理影片結束後的返回點擊事件
 */
void handleVideoPlayerClick() {
  if (!isVideoFinished) return; // 影片沒播完前，滑鼠點擊無效
  
  float btnW = 240;
  float btnH = 55;
  float btnX = width/2 - btnW/2;
  float btnY = height/2 + 80;
  
  // 檢查是否點擊了「返回教學範例」按鈕
  if (mouseX >= btnX && mouseX <= btnX + btnW && mouseY >= btnY && mouseY <= btnY + btnH) {
    returnToInstructions();
  }
}

/**
 * 輔助函式：安全關閉影片並恢復主系統音效
 */
void returnToInstructions() {
  if (currentMovie != null) {
    currentMovie.stop();
    currentMovie = null;
  }
  
  // 恢復主畫面背景循環音樂
  if (bgm != null && !bgm.isPlaying()) {
    bgm.loop();
  }
  
  currentState = State.INSTRUCTIONS;
}

/**
 * 轉譯易讀的中文影片分類名稱
 */
String getFriendlyVideoName() {
  if (currentVideoName.equals("use.mp4")) return "滅火方式";
  if (currentVideoName.equals("fire1.mp4")) return "A,B類火災應對";
  if (currentVideoName.equals("fire2.mp4")) return "B,C類火災應對";
  return currentVideoName;
}

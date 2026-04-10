/**
 * UI.pde
 * 所有純繪製介面組件，只讀全域變數，不修改任何狀態
 */

void drawMissionSelectScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  
  // 標題
  fill(255);
  textSize(32);
  text("請選擇訓練任務", width/2, 80); // 標題稍微往上移一點 (100 -> 80)

  // 任務卡片繪製 [cite: 181]
  for (int i = 0; i < missions.length; i++) {
    float x = width/2;
    
    // ---> 關鍵修改：調整卡片的起始高度與間隔 <---
    // 原本是 250 + i * 120
    // 現在改成從 Y=180 開始，每個間距 105
    float y = 180 + i * 105; 
    
    // 選中效果
    if (i == selectedMissionIdx) {
      fill(0, 150, 255, 100);
      stroke(0, 200, 255);
      strokeWeight(3);
      // 卡片高度也稍微縮減一點點 (100 -> 90) 讓視覺更輕盈
      rect(x - 250, y - 45, 500, 90, 15);
    } else {
      fill(60);
      noStroke();
      rect(x - 250, y - 45, 500, 90, 15);
    }
    
    fill(255);
    textSize(22);
    text(missions[i].name, x, y - 10);
    textSize(14);
    fill(200);
    text(missions[i].description, x, y + 20);
  }
  
  // 操作提示
  fill(255, 200, 0);
  textSize(16);
  text("使用上下鍵 [↑][↓] 切換，按 [Enter] 開始演練", width/2, height - 50); // 提示也微調往下放
  popStyle();
}

// === UI.pde ===
void drawpictures(){
  PImage currentBg = missionPics[selectedMissionIdx];
  if (currentBg != null) {
    pushStyle();
    imageMode(CORNER);
    
    // 畫背景 (保留你原本的 tint 設定)
    tint(255, 150); 
    image(currentBg, 0, 0, width, height);
    
    // ---> 新增：畫上對應的 5 個家具素材 <---
    noTint();          // 家具通常不需要變暗，恢復正常亮度
    imageMode(CENTER); // 改用中心點對齊，方便排版與日後加上火源
    
    for (int j = 0; j < 5; j++) {
      PImage fPic = furniturePics[selectedMissionIdx][j];
      PVector fPos = furniturePositions[selectedMissionIdx][j];
      
      if (fPic != null) {
        // 這裡直接畫出家具，若家具圖太大，可以加上寬高參數縮放：image(fPic, fPos.x, fPos.y, 寬, 高);
        image(fPic, fPos.x, fPos.y); 
      }
    }
    
    popStyle();
  }
}


/**
 * 繪製動態準心 (Dynamic Reticle)
 */
void drawCrosshair(float x, float y, float r) {
  pushStyle();
  noFill();
  stroke(0, 255, 0);
  strokeWeight(2);
  ellipse(x, y, r * 2, r * 2);
  line(x - 10, y, x + 10, y);
  line(x, y - 10, x, y + 10);
  popStyle();
}

/**
 * 繪製左上角任務目標
 */
void drawMissionInfo() {
  pushStyle();
  textFont(mainFont);
  fill(255);
  textSize(14);
  textAlign(LEFT);
  String mission = "任務目標: 撲滅 " + (currentFireType == FireType.GENERAL ? "A 類普通火災" : "電器火災");
  text(mission, 20, 30);
  popStyle();
}

/**
 * 繪製上方進度條
 */
void drawProgressBar() {
  pushStyle();
  textFont(mainFont);
  fill(50);
  stroke(100);
  strokeWeight(2);
  rect(width/2 - 200, 50, 400, 20);

  fill(0, 255, 100);
  noStroke();
  float progress = map(100 - fireHealth, 0, 100, 0, 400);
  rect(width/2 - 200, 50, progress, 20);

  fill(255);
  textSize(12);
  textAlign(CENTER);
  text(int(100 - fireHealth) + "%", width/2, 67);
  popStyle();
}

/**
 * 繪製右上角倒數計時器
 */
void drawTimer() {
  pushStyle();
  textFont(mainFont);
  fill(remainingTime < 30 ? color(255, 0, 0) : color(100, 200, 255));
  textSize(24);
  textAlign(RIGHT);
  int minutes = remainingTime / 60;
  int seconds = remainingTime % 60;
  String timeStr = String.format("%02d:%02d", minutes, seconds);
  text(timeStr, width - 30, 70);
  popStyle();
}

/**
 * 繪製左下角工具選擇區
 */
void drawEquipmentSection() {
  pushStyle();
  textFont(mainFont);
  fill(60);
  stroke(100);
  strokeWeight(2);
  rect(20, height - 120, 200, 100);

  fill(255);
  textSize(12);
  textAlign(LEFT);
  text("當前工具:", 30, height - 100);
  text(agentNames[currentAgent.ordinal()], 30, height - 80);

  if (currentFireType == FireType.ELECTRICAL && currentAgent == Agent.WATER) {
    fill(255, 0, 0);
    text("⚠ 電器火災不可用水!", 30, height - 50);
  }

  popStyle();
}

/**
 * 繪製右下角壓力計量表
 */
void drawPressureGauge() {
  pushStyle();
  textFont(mainFont);
  fill(60);
  stroke(100);
  strokeWeight(2);
  rect(width - 220, height - 120, 200, 100);

  fill(255);
  textSize(12);
  textAlign(LEFT);
  text("滅火器狀態:", width - 210, height - 100);
  text("壓力: " + int(extinguisherPressure) + "%", width - 210, height - 80);

  fill(50);
  rect(width - 210, height - 50, 180, 15);
  fill(extinguisherPressure > 30 ? color(100, 200, 100) : color(255, 100, 100));
  rect(width - 210, height - 50, map(extinguisherPressure, 0, 100, 0, 180), 15);

  popStyle();
}

/**
 * 繪製智能反饋提示
 */
void drawSmartFeedback() {
  pushStyle();
  textFont(mainFont);

  if (fireHealth > 0 && extinguisherPressure < 10) {
    fill(255, 0, 0, 200);
    textSize(16);
    textAlign(CENTER);
    text("⚠ 壓力不足，請用力按壓握把", width/2, height - 80);
  } else if (crosshairPos.y < 350) {
    fill(255, 200, 100, 200);
    textSize(14);
    textAlign(CENTER);
    text("[*] 請瞄準火源根部噴灑!", width/2, height - 80);
  }

  popStyle();
}

/**
 * 繪製開始畫面
 */
void drawStartScreen() {
  pushStyle();
  textFont(mainFont);
  fill(255);
  textSize(32);
  textAlign(CENTER);
  text("消防演練訓練系統", width/2, height/2 - 80);
  textSize(20);
  text("按任意鍵開始挑戰", width/2, height/2 - 20);
  text("滑鼠點擊模擬按壓握把", width/2, height/2 + 20);
  textSize(16);
  text("鍵盤 1/2/3 切換滅火劑", width/2, height/2 + 60);
  popStyle();
}

/**
 * 繪製結果畫面
 */
void drawResultScreen() {
  pushStyle();
  textFont(mainFont);
  fill(0, 0, 0, 180);
  rect(0, 0, width, height);
  fill(255);
  textSize(32);
  textAlign(CENTER);
  if (fireHealth <= 0) {
    fill(0, 255, 100);
    text("[v] 成功! 火災已撲滅", width/2, height/2 - 40);
    textSize(16);
    fill(255);
    text("用時: " + (180 - remainingTime) + " 秒", width/2, height/2 + 20);
  } else {
    fill(255, 100, 100);
    text("[x] 失敗! 時間已用盡", width/2, height/2);
  }
  textSize(14);
  text("按 R 鍵重新開始", width/2, height - 60);
  popStyle();
}

/**
 * UI.pde
 * 所有純繪製介面組件，只讀全域變數，不修改任何狀態
 */

void drawMissionSelectScreen() {
  pushStyle();
  textAlign(CENTER, CENTER);
  
  // 1. 標題：稍微再往上移一點，騰出空間給下方的卡片
  fill(255);
  textSize(32);
  text("請選擇訓練任務", width/2, 60); 

  // 2. 任務卡片繪製 (前 5 個一般任務)
  for (int i = 0; i < missions.length; i++) {
    float x = width/2;
    
    // ---> 關鍵修改：起始高度改為 130，間隔縮小為 85 <---
    float y = 130 + i * 85; 

    // 選中效果
    if (i == selectedMissionIdx) {
      fill(0, 150, 255, 100);
      stroke(0, 200, 255);
      strokeWeight(3);
    } else {
      fill(60);
      noStroke();
    }
    
    // 卡片高度也稍微縮減為 75，讓視覺更輕盈不擁擠
    rect(x - 250, y - 37, 500, 75, 15);
    
    fill(255);
    textSize(22);
    text(missions[i].name, x, y - 10);
    textSize(14);
    fill(200);
    text(missions[i].description, x, y + 15);
  }
  
  // 3. ---> 新增：畫出第 6 個選項（遊戲說明指南） <---
  int instructionIdx = missions.length; // 它的索引值會是 5
  float instX = width/2;
  float instY = 130 + instructionIdx * 85; // 套用跟上面一樣的間距公式

  // 說明的選中效果 (用專屬的黃色高亮，跟任務做區分)
  if (instructionIdx == selectedMissionIdx) {
    fill(255, 200, 0, 100); 
    stroke(255, 200, 0);
    strokeWeight(3);
  } else {
    fill(60);
    noStroke();
  }
  rect(instX - 250, instY - 37, 500, 75, 15);

  fill(255, 200, 0);
  textSize(22);
  text("📖 遊戲說明指南", instX, instY);

  // 4. 操作提示 (稍微往下放一點，並改為確認)
  fill(255, 200, 0);
  textSize(16);
  text("使用上下鍵 [↑][↓] 切換，按 [Enter] 確認", width/2, height - 30); 

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

/**
 * 繪製遊戲說明畫面
 */
void drawInstructionsScreen() {
  pushStyle();
  // 畫一個半透明黑底，蓋在原本的畫面上，讓文字更清晰
  fill(0, 0, 0, 230); 
  rect(0, 0, width, height);

  // --- 標題區 ---
  fill(255);
  textAlign(CENTER, TOP);
  textSize(40);
  text("【 消 防 演 練 指 南 】", width/2, 80);

  // --- 內容排版設定 ---
  textAlign(LEFT, TOP);
  textSize(24);
  float startX = width/2 - 350;
  float startY = 180;
  int lineSpace = 45;

  // --- 說明文字區 ---
  fill(255);
  text("1. 選擇任務後，請仔細觀察背景畫面中的", startX, startY);
  fill(255, 100, 100);
  text("起火點位置", startX + 460, startY);
  
  fill(255);
  text("2. 判斷火災類型與選用滅火器：", startX, startY + lineSpace * 1.5);
  
  fill(255, 200, 100);
  text("   ▶ 普通火災 (沙發、木櫃等)：", startX, startY + lineSpace * 2.5);
  fill(200);
  text("可使用任何種類滅火器", startX + 380, startY + lineSpace * 2.5);
  
  fill(100, 200, 255);
  text("   ▶ 電器火災 (電視、電箱等)：", startX, startY + lineSpace * 3.5);
  fill(255, 50, 50);
  text("嚴禁用水！請切換乾粉或 CO2", startX + 380, startY + lineSpace * 3.5);

  fill(255);
  text("3. 基礎操作方式：", startX, startY + lineSpace * 5.5);
  fill(200);
  text("   - 瞄準：移動滑鼠將準心對準火源根部", startX, startY + lineSpace * 6.5);
  text("   - 噴灑：按住滑鼠左鍵", startX, startY + lineSpace * 7.5);
  text("   - 切換：鍵盤按 1 (水) / 2 (乾粉) / 3 (CO2)", startX, startY + lineSpace * 8.5);

  // --- 底部返回提示 ---
  // 完美沿用你的設定：按 R 鍵回主畫面
  fill(0, 255, 100);
  textAlign(CENTER, BOTTOM);
  textSize(22);
  text("按 [R] 鍵返回主畫面", width/2, height - 50);

  popStyle();
}

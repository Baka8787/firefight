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
/**
 * 繪製左上角任務目標 (動態對應所有火災類型)
 */
/**
 * 繪製左上角任務目標 (精簡小巧版)
 */
void drawMissionInfo() {
  pushStyle();
  textFont(mainFont);
  
  // 1. 根據目前任務類型決定顯示名稱
  String typeStr = "";
  switch(currentFireType) {
    case GENERAL:    typeStr = "A類普通火災"; break;
    case ELECTRICAL: typeStr = "C類電器火災"; break;
    case OIL:        typeStr = "B類油類火災"; break;
    case METAL:      typeStr = "D類金屬火災"; break;
  }

  // 2. 繪製更細長的半透明底框 (高度從 85 降到 60)
  noStroke();
  fill(0, 0, 0, 120); // 透明度也稍微調低，更清爽
  rect(10, 10, 380, 60, 5);

  // 3. 顯示任務主標題 (字體從 20 降到 16)
  fill(255, 230, 0); 
  textSize(16);
  textAlign(LEFT, TOP);
  text("目標：" + typeStr, 20, 18);

  // 4. 顯示詳細描述 (字體從 14 降到 12)
  fill(220); 
  textSize(12);
  // 稍微調整位置，緊跟在標題下方
  text(missions[selectedMissionIdx].description, 20, 42);

  popStyle();
}
/**
 * 繪製上方進度條
 */
void drawProgressBar() {
  pushStyle();
  textFont(mainFont);
  
  // 1. 繪製進度條底框 (深灰色)
  float barX = width/2 - 200;
  float barY = 50;
  float barW = 400;
  float barH = 20;
  
  fill(50);
  stroke(100);
  strokeWeight(2);
  rect(barX, barY, barW, barH); 

  // 2. 繪製滅火進度 (亮綠色)
  // 計算目前撲滅了多少百分比 (100 - 剩餘血量)
  float progressPercent = 100 - fireHealth;
  float progressW = map(progressPercent, 0, 100, 0, barW);
  
  fill(0, 255, 100);
  noStroke();
  rect(barX, barY, progressW, barH);

  // 3. 關鍵：在正中間顯示進度數字
  fill(255); // 白色文字
  textSize(12);
  textAlign(CENTER, CENTER); // 水平垂直皆置中
  
  // 計算中心點：barX + 半寬, barY + 半高
  // 使用 round() 讓百分比顯示整數比較美觀
  text(round(progressPercent) + "%", barX + barW/2, barY + barH/2);
  
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

  // ---> 升級後的警告判定邏輯 <---
  fill(255, 0, 0); // 統一設定警告字體為紅色
  
  if (currentFireType == FireType.GENERAL && (currentAgent == Agent.CO2 || currentAgent == Agent.METAL)) {
    // 普通火災只能用水、乾粉
    text("⚠ 普通火災請用水或乾粉!", 30, height - 50);
    
  } else if (currentFireType == FireType.ELECTRICAL && (currentAgent == Agent.POWDER || currentAgent == Agent.METAL)) {
    // 電器火災只能用水、CO2
    text("⚠ 此藥劑對電器無效!", 30, height - 50);
    
  } else if (currentFireType == FireType.OIL && (currentAgent == Agent.POWDER || currentAgent == Agent.METAL)) {
    // 油類火災只能用水、CO2
    text("⚠ 此藥劑對油類無效!", 30, height - 50);
    
  } else if (currentFireType == FireType.METAL && currentAgent != Agent.METAL) {
    // 金屬火災只能用金屬專用滅火劑
    text("⚠ 嚴重警告：金屬火災禁用此藥劑!", 30, height - 50);
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
  
  // 這裡只保留原本這行，並確保它在正確的高度
  text("壓力: " + (int)(extinguisherPressure) + "%", width - 210, height - 80);

  // --- 進度條繪製 ---
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
  text("2. 判斷火災類型與選用滅火器：", startX, startY + lineSpace * 1.5f);
  
  fill(255, 200, 100);
  text("   ▶ 普通火災 (沙發、木櫃等)：", startX, startY + lineSpace * 2.5f);
  fill(200);
  text("可使用任何種類滅火器", startX + 380, startY + lineSpace * 2.5f);
  
  fill(100, 200, 255);
  text("   ▶ 電器火災 (電視、電箱等)：", startX, startY + lineSpace * 3.5f);
  fill(255, 50, 50);
  text("嚴禁用水！請切換乾粉或 CO2", startX + 380, startY + lineSpace * 3.5f);

  fill(255);
  text("3. 基礎操作方式：", startX, startY + lineSpace * 5.5f);
  fill(200);
  text("   - 瞄準：移動滑鼠將準心對準火源根部", startX, startY + lineSpace * 6.5f);
  text("   - 噴灑：按住滑鼠左鍵", startX, startY + lineSpace * 7.5f);
  text("   - 切換：鍵盤按 1 (水) / 2 (乾粉) / 3 (CO2)", startX, startY + lineSpace * 8.5f);

  // --- 底部返回提示 ---
  // 完美沿用你的設定：按 R 鍵回主畫面
  fill(0, 255, 100);
  textAlign(CENTER, BOTTOM);
  textSize(22);
  text("按 [R] 鍵返回主畫面", width/2, height - 50);

  popStyle();
}

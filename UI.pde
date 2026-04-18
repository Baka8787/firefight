/**
 * UI.pde
 * 所有純繪製介面組件，只讀全域變數，不修改任何狀態
 * 
 * 改進版本：現代簡約 HUD 風格
 * - 模組化資訊區塊
 * - 優化配色與層次感
 * - 增強視覺專業度
 */

// ============================================
// 輔助繪製函式
// ============================================

/**
 * 繪製標準資訊區塊（模組化）
 * @param x 左上角 X 座標
 * @param y 左上角 Y 座標
 * @param w 寬度
 * @param h 高度
 * @param label 標籤文自
 * @param value 數值顯示（支援多行時右對齊）
 * @param valColor 數值顏色
 */
void drawInfoBlock(float x, float y, float w, float h, String label, String value, color valColor) {
  pushStyle();
  
  // 背景框（使用統一的配色常數）
  fill(INFO_BLOCK_BG);
  stroke(BORDER_SUBTLE);
  strokeWeight(1);
  rect(x, y, w, h, 8); // 8px 圓角
  
  // 標籤文字（上方）
  fill(TEXT_SECONDARY);
  textSize(12);
  textAlign(LEFT, TOP);
  textFont(mainFont);
  text(label, x + 10, y + 8);
  
  // 數值文字（右下方，加粗視覺）
  fill(valColor);
  textSize(20);
  textAlign(RIGHT, BOTTOM);
  textFont(mainFont);
  text(value, x + w - 10, y + h - 6);
  
  popStyle();
}

/**
 * 繪製水平進度條
 * @param x 左上角 X
 * @param y 左上角 Y
 * @param w 寬度
 * @param h 高度
 * @param percent 百分比 (0~1)
 * @param barColor 進度條顏色
 */
void drawHorizontalBar(float x, float y, float w, float h, float percent, color barColor) {
  pushStyle();
  
  // 背景條（深色）
  fill(BAR_BG);
  stroke(BORDER_SUBTLE);
  strokeWeight(1);
  rect(x, y, w, h, 4);
  
  // 進度條（亮色）
  fill(barColor);
  noStroke();
  rect(x, y, w * constrain(percent, 0, 1), h, 4);
  
  popStyle();
}

/**
 * 繪製網格背景裝飾（用於開頭畫面）
 */
void drawGridDecoration() {
  pushStyle();
  stroke(255, 20);
  strokeWeight(1);
  
  float gridSize = 40;
  for (float x = 0; x < width; x += gridSize) {
    line(x, 0, x, height);
  }
  for (float y = 0; y < height; y += gridSize) {
    line(0, y, width, y);
  }
  
  popStyle();
}

/**
 * 繪製頂部狀態欄（計時器 & 壓力表）
 */
void drawTopStatus() {
  // 左上：計時器
  int minutes = remainingTime / 60;
  int seconds = remainingTime % 60;
  String timeStr = String.format("%02d:%02d", minutes, seconds);
  color timerColor = getTimerColor(remainingTime, missions[selectedMissionIdx].timeLimit);
  drawInfoBlock(880, 20, 160, 80, "剩余時間", timeStr, timerColor);
  
  // 右上：壓力表（含進度條）
  color pressureColor = extinguisherPressure > 30 ? STATUS_SUCCESS : STATUS_DANGER;
  drawInfoBlock(width - 180, 20, 160, 110, "滅火器", (int)extinguisherPressure + "%", pressureColor);
  drawHorizontalBar(width - 150, 70, 120, 6, extinguisherPressure / 100.0, pressureColor);
}

// ============================================
// 原有 UI 繪製函式（優化版）
// ============================================

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

  // 4. 硬體設定選項
  int hwIdx = missions.length + 1;
  float hwX = width/2;
  float hwY = 130 + hwIdx * 85;

  if (hwIdx == selectedMissionIdx) {
    fill(100, 200, 255, 100);
    stroke(100, 200, 255);
    strokeWeight(3);
  } else {
    fill(60);
    noStroke();
  }
  rect(hwX - 250, hwY - 37, 500, 75, 15);

  fill(100, 200, 255);
  textSize(22);
  text("硬體設定", hwX, hwY);

  // 5. 操作提示 (稍微往下放一點，並改為確認)
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
 * 繪製左上角任務目標（優化版：精簡小巧）
 */
void drawMissionInfo() {
  pushStyle();
  textFont(mainFont);
  
  // 1. 根據目前任務類型決定顯示名稱
  String typeStr = "";
  color fireColor = color(200, 200, 200);
  switch(currentFireType) {
    case GENERAL:    typeStr = "A類普通火災"; fireColor = getFireTypeColor(FireType.GENERAL); break;
    case ELECTRICAL: typeStr = "C類電器火災"; fireColor = getFireTypeColor(FireType.ELECTRICAL); break;
    case OIL:        typeStr = "B類油類火災"; fireColor = getFireTypeColor(FireType.OIL); break;
    case METAL:      typeStr = "D類金屬火災"; fireColor = getFireTypeColor(FireType.METAL); break;
  }

  // 2. 繪製更細長的半透明底框
  noStroke();
  fill(INFO_BLOCK_BG);
  rect(10, 10, 380, 60, 8); // 使用 8px 圓角

  // 3. 顯示任務主標題
  fill(ACCENT_YELLOW); // 米黃色，柔和而顯眼
  textSize(16);
  textAlign(LEFT, TOP);
  text("目標：" + typeStr, 20, 18);

  // 4. 顯示詳細描述
  fill(TEXT_SECONDARY); // 淡灰色
  textSize(12);
  text(missions[selectedMissionIdx].description, 20, 42);

  popStyle();
}
/**
 * 繪製上方進度條（優化版：現代化設計）
 */
void drawProgressBar() {
  pushStyle();
  textFont(mainFont);
  
  // 計算滅火進度百分比
  float progressPercent = 100 - fireHealth;
  
  // 背景框與進度條容器
  float barX = width/2 - 180;
  float barY = 60;
  float barW = 360;
  float barH = 12;
  
  // 進度條背景
  fill(BAR_BG);
  stroke(BORDER_SUBTLE);
  strokeWeight(1);
  rect(barX, barY, barW, barH, 6);
  
  // 進度條前景（綠色）
  fill(BAR_PROGRESS_OK);
  noStroke();
  float progressW = map(progressPercent, 0, 100, 0, barW);
  rect(barX, barY, progressW, barH, 6);
  
  // 進度百分比文字（置中於進度條中央）
  fill(TEXT_PRIMARY);
  textSize(14);
  textAlign(CENTER, CENTER);
  text(round(progressPercent) + "%", barX + barW/2, barY + barH/2);
  
  popStyle();
}

/**
 * 繪製右上角倒數計時器（已整合至 drawTopStatus）
 * @deprecated 此函式已整合，保留以相容舊代碼
 */
void drawTimer() {
  // 計時器已整合至 drawTopStatus()，此函式保留以相容既有調用
}

/**
 * 繪製左下角工具選擇區（優化版）
 */
void drawEquipmentSection() {
  pushStyle();
  textFont(mainFont);
  
  // 繪製背景框（使用新風格）
  fill(INFO_BLOCK_BG);
  stroke(BORDER_SUBTLE);
  strokeWeight(1.5);
  rect(20, height - 120, 200, 100, 8);

  // 標籤
  fill(TEXT_SECONDARY);
  textSize(12);
  textAlign(LEFT, TOP);
  text("當前工具", 30, height - 105);
  
  // 目前選中的藥劑名稱（使用藥劑對應色）
  fill(getAgentColor(currentAgent));
  textSize(18);
  text(agentNames[currentAgent.ordinal()], 30, height - 80);

  // --- 警告判定邏輯（使用柔紅色 #FF6464） ---
  fill(STATUS_DANGER);
  textSize(11);
  
  if (currentFireType == FireType.GENERAL && (currentAgent == Agent.CO2 || currentAgent == Agent.METAL)) {
    text("⚠ 普通火災請用水或乾粉!", 30, height - 50);
    
  } else if (currentFireType == FireType.ELECTRICAL && (currentAgent == Agent.POWDER || currentAgent == Agent.METAL)) {
    text("⚠ 此藥劑對電器無效!", 30, height - 50);
    
  } else if (currentFireType == FireType.OIL && (currentAgent == Agent.POWDER || currentAgent == Agent.METAL)) {
    text("⚠ 此藥劑對油類無效!", 30, height - 50);
    
  } else if (currentFireType == FireType.METAL && currentAgent != Agent.METAL) {
    text("⚠ 嚴重警告：金屬火災禁用此!!", 30, height - 50);
  }

  popStyle();
}

/**
 * 繪製右下角壓力計量表（已整合至 drawTopStatus）
 * @deprecated 此函式已整合，保留以相容舊代碼
 */
void drawPressureGauge() {
  // 壓力表已整合至 drawTopStatus() 的右上方，此函式保留以相容既有調用
}

/**
 * 繪製智能反饋提示（優化版：柔和配色）
 */
void drawSmartFeedback() {
  pushStyle();
  textFont(mainFont);

  if (fireHealth > 0 && extinguisherPressure < 10) {
    // 壓力不足警告（柔紅色）
    fill(STATUS_DANGER, 200);
    textSize(16);
    textAlign(CENTER);
    text("⚠ 壓力不足，請用力按壓握把", width/2, height - 80);
    
  } else {
    // 動態判斷是否瞄準太高
    // 遍歷所有起火點，檢查準心與起火點的高度差
    boolean aimingTooHigh = false;
    for (FireSource fs : fireSources) {
      if (fs.active && (fs.pos.y - crosshairPos.y) > 60) { 
        aimingTooHigh = true;
        break;
      }
    }

    if (aimingTooHigh) {
      fill(255, 200, 100, 200);
      textSize(16);
      textAlign(CENTER);
      text("⚠ 請瞄準火源根部噴灑！", width/2, height - 80);
    }
  }

  popStyle();
}

/**
 * 繪製開始畫面（優化版：科技感與引導性）
 */
void drawStartScreen() {
  background(BG_DARK);
  
  // 1. 繪製背景裝飾線（模擬網格）
  drawGridDecoration(); 
  
  // 2. 標題與陰影效果
  pushStyle();
  textAlign(CENTER, CENTER);
  textFont(mainFont);
  
  // 標題陰影
  fill(0, 100);
  textSize(64);
  text("虛擬滅火訓練系統", width/2 + 3, height/3 + 3);
  
  // 標題主色
  fill(ACCENT_YELLOW);
  text("虛擬滅火訓練系統", width/2, height/3);
  
  // 3. 英文副標
  textSize(18);
  fill(TEXT_SECONDARY);
  text("Virtual Firefighting Training System v1.0", width/2, height/3 + 50);
  
  // 4. 引導文字（閃爍效果）
  textSize(22);
  if (frameCount % 80 < 50) { // 每秒閃爍
    fill(STATUS_WARNING);
  } else {
    fill(STATUS_WARNING, 50);
  }
  text(">>> 按任意鍵開始 <<<", width/2, height * 0.65);
  
  // 5. 操作提示（靜態文字）
  textSize(16);
  fill(color(150, 180, 220));
  text("滑鼠移動瞄準  |  左鍵模擬按壓  |  數字鍵 1-4 切換藥劑", width/2, height * 0.75);
  
  // 6. 底部版權宣告
  textSize(12);
  fill(color(100, 120, 150));
  text("Engineering & Safety Lab © 2024-2025", width/2, height - 30);
  
  popStyle();
}

/**
 * 繪製結果畫面（優化版：現代化與蘊感傳達）
 */
void drawResultScreen() {
  pushStyle();
  textFont(mainFont);
  
  // 半透明黑底遮罩
  fill(OVERLAY_DARK);
  rect(0, 0, width, height);
  
  // 取得當前任務的總時間限制
  int totalMissionTime = missions[selectedMissionIdx].timeLimit;
  float timeRatio = (float)remainingTime / totalMissionTime;
  
  // 設定文字完全置中對齊
  textAlign(CENTER, CENTER);

  if (fireHealth <= 0 && remainingTime > 0) {
    // === 滅火成功：根據時間比例給予 A, B, C 評級 ===
    String grade = "";
    color gradeColor;
    String feedbackMsg = "";

    if (timeRatio > 0.75f) {
      grade = "A";
      gradeColor = STATUS_SUCCESS;
      feedbackMsg = "完美撲滅！反應迅速，你是天生的打火英雄！";
    } else if (timeRatio > 0.50f) {
      grade = "B";
      gradeColor = STATUS_WARNING;
      feedbackMsg = "表現不錯！火勢已順利受控，下次可以再快一點喔！";
    } else {
      grade = "C";
      gradeColor = color(255, 150, 100);
      feedbackMsg = "好險！千鈞一髮完成任務，請再多熟悉藥劑與瞄準技巧！";
    }

    // 1. 顯示成功標題
    textSize(36);
    fill(STATUS_SUCCESS);
    text("[✓] 任務成功！火災已撲滅", width/2, height/2 - 120);

    // 2. 顯示評級大字
    textSize(100);
    fill(gradeColor);
    text(grade, width/2, height/2 - 10);

    // 3. 顯示回饋語
    textSize(20);
    fill(color(220, 220, 180));
    text(feedbackMsg, width/2, height/2 + 60);

    // 4. 顯示詳細用時
    textSize(16);
    fill(TEXT_SECONDARY);
    int timeUsed = totalMissionTime - remainingTime;
    text("任務用時: " + timeUsed + "秒  |  總時限: " + totalMissionTime + "秒", width/2, height/2 + 110);

  } else {
    // === 滅火失敗：時間歸零 ===
    
    // 1. 顯示失敗標題
    textSize(36);
    fill(STATUS_DANGER);
    text("[✗] 任務失敗！時間已用盡", width/2, height/2 - 120);
    
    // 2. 顯示 F 評級
    textSize(100);
    fill(STATUS_CRITICAL); 
    text("F", width/2, height/2 - 10);
    
    // 3. 顯示失敗回饋語
    textSize(20);
    fill(color(255, 180, 180)); 
    text("挑戰失敗！火勢已失控，請記住各類火災的", width/2, height/2 + 50);
    text("正確應對方式，再來一次！", width/2, height/2 + 80);
  }

  // 底部重新開始提示
  textSize(18);
  fill(ACCENT_YELLOW);
  text("▶ 按 [R] 鍵返回主畫面 ◀", width/2, height - 60);
  
  popStyle();
}




/**
 * 整合遊戲進行中的所有UI元素繪製
 * 建議在 main.pde 的 draw() 函數中調用此函數
 */
void drawGameplayUI() {
  // 繪製背景圖片
  drawpictures();
  
  // 繪製頂部狀態欄（計時器 & 壓力表）
  drawTopStatus();
  
  // 繪製左上角任務目標
  drawMissionInfo();
  
  // 繪製中央進度條
  drawProgressBar();
  
  // 繪製動態準心
  drawCrosshair(crosshairPos.x, crosshairPos.y, 30);
  
  // 繪製左下角工具選擇區
  drawEquipmentSection();
  
  // 繪製智能反饋提示（中央）
  drawSmartFeedback();
}

/**
 * 繪製遊戲說明畫面（優化版）
 */
void drawInstructionsScreen() {
  pushStyle();
  // 畫一個半透明黑底，蓋在原本的畫面上
  fill(OVERLAY_DARK); 
  rect(0, 0, width, height);

  // --- 標題區 ---
  fill(ACCENT_YELLOW);
  textAlign(CENTER, TOP);
  textSize(40);
  textFont(mainFont);
  text("【 消 防 演 練 指 南 】", width/2, 60);

  // --- 內容排版設定 ---
  textAlign(LEFT, TOP);
  textSize(20);
  float startX = width/2 - 380;
  float startY = 140;
  float lineSpace = 38;

  // --- 1. 觀察目標 ---
  fill(TEXT_SECONDARY);
  text("1. 選擇任務後，請觀察背景中的", startX, startY);
  fill(STATUS_WARNING);
  textSize(20);
  text("起火點位置與火災類型", startX + 330, startY);
  
  // --- 2. 火災分類與藥劑 ---
  textSize(20);
  fill(TEXT_SECONDARY);
  text("2. 判斷火災類型並選用正確藥劑：", startX, startY + lineSpace * 1.5f);
  
  // A類
  textSize(18);
  fill(getFireTypeColor(FireType.GENERAL));
  text("   ▶ 普通火災 (木材、紙張)：", startX, startY + lineSpace * 2.5f);
  fill(TEXT_WEAK);
  text("推薦使用 水、乾粉", startX + 380, startY + lineSpace * 2.5f);
  
  // C類
  fill(getFireTypeColor(FireType.ELECTRICAL));
  text("   ▶ 電器火災 (插座、電箱)：", startX, startY + lineSpace * 3.5f);
  fill(TEXT_WEAK);
  text("推薦使用 水、CO2", startX + 380, startY + lineSpace * 3.5f);

  // B類
  fill(getFireTypeColor(FireType.OIL));
  text("   ▶ 油類火災 (廚房油鍋)：", startX, startY + lineSpace * 4.5f);
  fill(TEXT_WEAK);
  text("推薦使用 水、CO2", startX + 380, startY + lineSpace * 4.5f);

  // D類
  fill(getFireTypeColor(FireType.METAL));
  text("   ▶ 金屬火災 (活性金屬)：", startX, startY + lineSpace * 5.5f);
  fill(STATUS_WARNING);
  text("⚠️ 必須使用金屬專用藥劑", startX + 380, startY + lineSpace * 5.5f);

  // --- 3. 操作方式 ---
  textSize(20);
  fill(TEXT_SECONDARY);
  text("3. 基礎操作方式：", startX, startY + lineSpace * 7.5f);
  textSize(18);
  fill(TEXT_WEAK);
  text("   - 瞄準：移動滑鼠將準心對準火源根部", startX, startY + lineSpace * 8.5f);
  text("   - 噴灑：按住滑鼠左鍵進行滅火", startX, startY + lineSpace * 9.5f);
  
  fill(ACCENT_CYAN);
  text("   - 切換：按 1(水) / 2(乾粉) / 3(CO2) / 4(金屬藥劑)", startX, startY + lineSpace * 10.5f);

  // --- 底部返回提示 ---
  fill(STATUS_SUCCESS);
  textAlign(CENTER, BOTTOM);
  textSize(20);
  text("按 [R] 鍵返回主畫面", width/2, height - 40);

  popStyle();
}

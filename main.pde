/**
 * Firefighting Training System - Core Logic
 * Language: Processing (Java-based)
 */
 
 
//新增:音效
import processing.sound.*;
SoundFile bgm;
SoundFile waterSfx;

// 系統狀態定義
enum State { START, SELECT_MISSION, PLAYING, RESULT, INSTRUCTIONS, SETTINGS }
enum FireType { GENERAL, ELECTRICAL, OIL, METAL }
enum Agent { WATER, POWDER, CO2, METAL }
State currentState = State.START;
boolean debugMode = false;

// 字型宣告
PFont mainFont;

// 物理與模擬變數
float extinguisherPressure = 100.0f; // 滅火器壓力 (%)
float fireHealth = 100.0f;           // 火源生命值
PVector targetPos, crosshairPos;    // 目標座標與平滑準心座標
PVector firePos;                     // 火源位置
float sprayRadius = 50;             // 噴灑半徑
Agent currentAgent = Agent.WATER;   // 當前選用的滅火劑

// 計時系統
int totalTime = 180;                // 總時間 (秒)
int remainingTime = 180;            // 剩餘時間
int lastTimeUpdate = 0;             // 上次更新時間（毫秒）

// 任務與類型
FireType currentFireType = FireType.GENERAL;  // 當前火源類型
// 2. 更新藥劑名稱陣列 (加入金屬滅火劑)
String[] agentNames = {"Water (水)", "ABC Powder (乾粉)", "CO2", "金屬專用滅火劑"};
float[] agentRadiusBonus = {1.0f, 0.9f, 1.1f, 1.0f}; // 補上第4個的半徑係數

// 粒子系統 (模擬滅火介質)
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<FireParticle> fireParticles = new ArrayList<FireParticle>(); // 火焰粒子系統
int MAX_PARTICLES = 1000; // 最大滅火粒子数量限制
int MAX_FIRE_PARTICLES = 290; // 更高火焰粒子上限，增強濃密感
float mockSensorValue; // 用於模擬感測器數據的變數


// 藥劑切換冷卻
int lastAgentSwitch = 0;
int agentSwitchCooldown = 500; // 500ms 冷卻時間

// 第一人稱噴管變數
float nozzleX, nozzleY;
float nozzleAngle = 0;
float lerpNozzleX, lerpNozzleY; // 平滑後的噴嘴座標

// 任務配置結構
class Mission {
  String name;
  int timeLimit;
  float initialHealth;
  String description;
  
  Mission(String n, int time, float hp, String desc) {
    name = n; timeLimit = time; initialHealth = hp; description = desc;
  }
}

Mission[] missions;


//新加:圖片
PImage[] missionPics = new PImage[5];

PVector[][] furniturePositions = new PVector[5][5]; // 紀錄每個家具的 X, Y 座標
// 新增：集中管理 25 個家具的精確座標 {X, Y}
// 結構為：manualCoords[任務編號][家具編號][0是X, 1是Y]
float[][][] manualCoords = {
  // 任務 0 (pic0) 的 5 個家具座標 {x, y}
  { {880, 450}, {300, 226}, {650, 430}, {500, 600}, {110, 480} },
  
  // 任務 1 (pic1) 的 5 個家具座標
  { {850, 280}, {1140, 480}, {650, 400}, {450,350}, {120, 440} },
  
  // 任務 2 (pic2) 的 5 個家具座標
  { {136, 526}, {300, 400}, {950, 420}, {1200, 476}, {720, 300} },
  
  // 任務 3 (pic3) 的 5 個家具座標
  { {1200, 400}, {150, 270}, {1000, 470}, {650, 600}, {300, 500} },
  
  // 任務 4 (pic4) 的 5 個家具座標
  { {250, 550}, {600, 510}, {800, 450}, {400, 450}, {1100, 530} }
};

FireType[][] manualFireTypes = {
  // 任務 0 (對應上面的 5 個點：普通, 電器, 普通, 普通, 電器)
  { FireType.GENERAL, FireType.GENERAL, FireType.GENERAL, FireType.GENERAL, FireType.GENERAL },
  // 任務 1
  { FireType.ELECTRICAL, FireType.ELECTRICAL, FireType.ELECTRICAL, FireType.ELECTRICAL, FireType.ELECTRICAL },
  // 任務 2
  { FireType.OIL, FireType.OIL, FireType.OIL, FireType.GENERAL, FireType.GENERAL },
  // 任務 3
  { FireType.METAL, FireType.METAL, FireType.METAL, FireType.METAL, FireType.METAL },
  // 任務 4
  { FireType.GENERAL, FireType.ELECTRICAL, FireType.OIL, FireType.GENERAL, FireType.ELECTRICAL }
};



int selectedMissionIdx = 0;

void setup() {
  size(1280, 720);
  pixelDensity(1);
  mainFont = createFont("Microsoft JhengHei", 32);
  textFont(mainFont);
  
  // ---> 新增：載入並開始循環播放音樂 <---
  bgm = new SoundFile(this, "VideoHead.mp3");
  bgm.loop();
  
  waterSfx = new SoundFile(this, "water.mp3");

  // 初始化任務陣列 [cite: 99-100]
  missions = new Mission[5];
  missions[0] = new Mission("普通火災演練", 120, 100, "撲滅A類普通火災（木材、紙張）");
  missions[1] = new Mission("電器火災挑戰", 90, 80, "電氣火災嚴禁使用水基滅火劑");
  missions[2] = new Mission("油類火災挑戰",  60, 150, "撲滅B類油類火災");
  missions[3] = new Mission("金屬火災演練",  80, 120, "高難度:涉及活性金屬，禁水性物質");
  missions[4] = new Mission("緊急複合演練", 150, 200, "高難度：氣爆後火勢蔓延極快");

  // ---> 關鍵修改：載入 5 張圖片 <---
  missionPics[0] = loadImage("pic0.jpg"); 
  missionPics[1] = loadImage("pic1.jpg");
  missionPics[2] = loadImage("pic2.jpg");
  missionPics[3] = loadImage("pic3.jpg"); // 新增
  missionPics[4] = loadImage("pic4.jpg"); // 新增
  
  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 5; j++) {
      // 載入圖片 (01.png ~ 45.png)
      
      // ---> 關鍵修改：讀取我們手動設定好的陣列座標 <---
      float x = manualCoords[i][j][0];
      float y = manualCoords[i][j][1];
      furniturePositions[i][j] = new PVector(x, y);
    }
  }

  firePos = new PVector(random(200, width-200), random(height*0.5, height*0.9));
  targetPos = new PVector(width/2, height/2);
  crosshairPos = new PVector(width/2, height/2);

  bridge = new SerialBridge(this);
  bridge.refreshPorts();
  mockSensorValue = 512;
}

void draw() {
  background(30);
  if (bridge != null) bridge.poll();
  
  switch(currentState) {
    case START: drawStartScreen(); break;
    case SELECT_MISSION: drawMissionSelectScreen(); break; // 新增狀態
    case PLAYING: updateSimulation(); drawGameUI(); break;
    case RESULT: drawResultScreen(); break;
    case INSTRUCTIONS: drawInstructionsScreen(); break;
    case SETTINGS: drawSettingsScreen(); break;
  }
}

/**
 * 更新模擬邏輯：包含座標插值與滅火判定
 */
  void updateSimulation() {
  // 0. 更新計時器
  updateTimer();
  
  // 如果時間已到，顯示失敗
  if (remainingTime <= 0) {
    currentState = State.RESULT;
    return;
  }
  
  // 如果火已滅，顯示成功
  if (fireHealth <= 0) {
    currentState = State.RESULT;
    return;
  }
  
  // 1. 更新目標位置
  if (bridge != null && bridge.ready) {
    targetPos.set(bridge.targetX(), bridge.targetY());
  } else {
    targetPos.set(mouseX, mouseY);
  }
  
  // 2. 準心平滑移動 (Linear Interpolation)
  crosshairPos.lerp(targetPos, 0.2); 

  // 3. 類比感測器數據映射 (模擬數據)
  // 假設力道越大，半徑越小 (20px - 150px)
  float sensorForce = getFilteredSensorData(); 
  sprayRadius = 50;

  
  // 4. 噴灑與壓力邏輯分離
  if (isPressing()) {
    if (currentAgent == Agent.WATER) {
      // 水管模式：持續噴灑，不扣壓力 [cite: 119]
      // 這裡 sensorForce 被 Particle.pde 用於控制 streamFactor (水霧 vs 水柱) [cite: 175-177]
      if (particles.size() < MAX_PARTICLES) {
        generateParticles(crosshairPos, sprayRadius);
      }
    } else {
      // 滅火器模式：有壓力才噴，且扣壓力 [cite: 120]
      // 這裡 sensorForce 透過 map 影響 sprayRadius (噴灑距離/範圍) [cite: 118]
      if (extinguisherPressure > 0) {
        if (particles.size() < MAX_PARTICLES) {
          generateParticles(crosshairPos, sprayRadius);
        }
        extinguisherPressure -= 0.12; // 消耗壓力
      }
    }
    checkExtinguishByCrosshair();
    if (!waterSfx.isPlaying()) waterSfx.play(); 
  } else {
    if (waterSfx.isPlaying()) waterSfx.stop();
  }
  
  // 5. 更新並描繪粒子（關鍵！）
  for (int i = particles.size()-1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    if (p.isDead()) {
      particles.remove(i);
    } else {
      p.display(); // 確保粒子被繪製出來
    }
  }
  
  // 6. 更新火焰粒子系統
  updateFireParticles();
}



// --- 介面組件 (UI Components) ---

void drawGameUI() {
  // 使用新的優化版UI系統
  drawGameplayUI();
  
  // 繪製火焰效果（保留原有邏輯）
  drawFire();
  if (debugMode) drawFireDebug();
  drawFireExtinguisher();
}

/**
 * 更新計時器
 */
void updateTimer() {
  if (currentState != State.PLAYING) return;
  
  int now = millis();
  if (now - lastTimeUpdate >= 1000) {
    remainingTime--;
    lastTimeUpdate = now;
  }
}


/**
 * 處理鍵盤輸入邏輯：支援狀態切換、任務選擇與藥劑控制
 */
// === main.pde ===

void keyPressed() {
  int now = millis();
  
  // 維持原設定：R 鍵無條件回到主畫面 (START)
  if (key == 'r' || key == 'R') {
    resetToStart();
    return;
  }

  switch (currentState) {

    case START:
      currentState = State.SELECT_MISSION;
      break;
      
    case SELECT_MISSION:
      // ---> 關鍵修改：選單總共有 7 個選項 (5個任務 + 說明 + 硬體設定) <---
      int totalOptions = missions.length + 2; 
      
      if (keyCode == UP) {
        selectedMissionIdx = (selectedMissionIdx - 1 + totalOptions) % totalOptions;
      } 
      else if (keyCode == DOWN) {
        selectedMissionIdx = (selectedMissionIdx + 1) % totalOptions;
      } 
      else if (key == ENTER || key == RETURN) {
        
        // 判斷按 Enter 時，玩家停在哪個選項上
        if (selectedMissionIdx < missions.length) {
          // 如果選的是 0~4，進入一般訓練任務
          initializeSelectedMission();
          currentState = State.PLAYING;
          lastTimeUpdate = millis();
          if (bgm.isPlaying()) bgm.stop();
        } 
        else if (selectedMissionIdx == missions.length) {
          currentState = State.INSTRUCTIONS;
        }
        else {
          if (bridge != null) bridge.refreshPorts();
          settingsIdx = 0;
          currentState = State.SETTINGS;
        }
      }
      break;

    // (INSTRUCTIONS 狀態不需要寫，因為 R 鍵會把它帶回 START)
      
    case PLAYING:
      if (now - lastAgentSwitch > agentSwitchCooldown) {
        if (key == 't' || key == 'T') {
          debugMode = !debugMode;
        }
        if (key == '1') { currentAgent = Agent.WATER; lastAgentSwitch = now; }
        else if (key == '2') { currentAgent = Agent.POWDER; lastAgentSwitch = now; }
        else if (key == '3') { currentAgent = Agent.CO2; lastAgentSwitch = now; }
        // ---> 新增：按 4 切換為金屬滅火劑 <---
        else if (key == '4') { currentAgent = Agent.METAL; lastAgentSwitch = now; }
      }
      break;

    case SETTINGS:
      handleSettingsKey();
      break;
  }
}

/**
 * 輔助函數：初始化所選任務的參數
 */
void initializeSelectedMission() {
  Mission m = missions[selectedMissionIdx];
  remainingTime = m.timeLimit;
  fireHealth = m.initialHealth;
  extinguisherPressure = 100.0f; 
  
  // 1. 從 0 到 4 隨機抽籤 (決定這次燒哪個位置)
  int randomIdx = int(random(5)); 
  
  // 2. 依據抽籤結果，讀取並設定火災類型 (GENERAL 或 ELECTRICAL)
  currentFireType = manualFireTypes[selectedMissionIdx][randomIdx];
  
  // 3. 依據抽籤結果，讀取並設定火源座標 (Y軸減30讓火往上飄一點)
  float targetX = manualCoords[selectedMissionIdx][randomIdx][0];
  float targetY = manualCoords[selectedMissionIdx][randomIdx][1];
  firePos = new PVector(targetX, targetY - 30); 
  
  // 4. 清理前一次的殘留粒子
  particles.clear();
  fireParticles.clear();
}
/**
 * 輔助函數：重置系統至初始狀態
 */
void resetToStart() {
  currentState = State.START;
  fireHealth = 100.0f; 
  extinguisherPressure = 100.0f; 
  remainingTime = 180; 
  particles.clear();
  fireParticles.clear(); 
  
  
  if (!bgm.isPlaying()) {
    bgm.loop();
  }
}
void mouseWheel(MouseEvent event) {
  float e = event.getCount(); // 滾輪向上為負，向下為正
  // 調整數值，限制在 0-1023 之間
  mockSensorValue = constrain(mockSensorValue - e * 50, 0, 1023); 
}
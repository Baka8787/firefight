/**
 * Firefighting Training System - Core Logic
 * Language: Processing (Java-based)
 */

// 系統狀態定義
enum State { START, PLAYING, RESULT }
enum FireType { GENERAL, ELECTRICAL }
enum Agent { WATER, POWDER, CO2 } 
State currentState = State.START;

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
String[] agentNames = {"Water (水)", "ABC Powder (乾粉)", "CO2"};
float[] agentRadiusBonus = {1.0f, 0.9f, 1.1f};  // 各填充物的半徑係數

// 粒子系統 (模擬滅火介質)
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<FireParticle> fireParticles = new ArrayList<FireParticle>(); // 火焰粒子系統
int MAX_PARTICLES = 500; // 最大滅火粒子数量限制
int MAX_FIRE_PARTICLES = 260; // 更高火焰粒子上限，增強濃密感


// 藥劑切換冷卻
int lastAgentSwitch = 0;
int agentSwitchCooldown = 500; // 500ms 冷卻時間

// 第一人稱噴管變數
float nozzleX, nozzleY;
float nozzleAngle = 0;
float lerpNozzleX, lerpNozzleY; // 平滑後的噴嘴座標

void setup() {
  size(1280, 720);
  
  // 解決中文字碼測醢 - Windows 使用安裝似愛戳正黑體
  mainFont = createFont("Microsoft JhengHei", 32);
  textFont(mainFont);
  
  // 初始化火源位置為隨機
  firePos = new PVector(random(200, width-200), random(height*0.5, height*0.9));
  
  targetPos = new PVector(width/2, height/2);
  crosshairPos = new PVector(width/2, height/2);
  textAlign(LEFT);
  textSize(16);
  
  // 初始化噴管位置
  nozzleX = width/2;
  nozzleY = height - 80;
  lerpNozzleX = nozzleX;
  lerpNozzleY = nozzleY;
}

void draw() {
  background(30);
  
  switch(currentState) {
    case START:
      drawStartScreen();
      break;
    case PLAYING:
      updateSimulation();
      drawGameUI();
      break;
    case RESULT:
      drawResultScreen();
      break;
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
  
  // 1. 更新目標位置為滑鼠座標（關鍵！）
  targetPos.set(mouseX, mouseY);
  
  // 2. 準心平滑移動 (Linear Interpolation)
  crosshairPos.lerp(targetPos, 0.2); 

  // 3. 類比感測器數據映射 (模擬數據)
  // 假設力道越大，半徑越小 (20px - 150px)
  float sensorForce = getFilteredSensorData(); 
  sprayRadius = map(sensorForce, 0, 1023, 150, 20);

  // 4. 滅火判定邏輯 - 現在由粒子碰撞處理
  if (isPressing() && extinguisherPressure > 0) {
    // 粒子數量雖限制
    if (particles.size() < MAX_PARTICLES) {
      generateParticles(crosshairPos, sprayRadius);
    }
    extinguisherPressure -= 0.1; // 消耗壓力
    checkExtinguishByCrosshair();
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
  // 底層：火焰
  drawFire();
  
  // 中層：噴灑粒子 (在 updateSimulation 裡已經 display 了)
  
  // 上層：滅火器實體
  drawFireExtinguisher();
  
  // 最上層：UI 資訊與準心
  drawProgressBar();
  drawTimer();
  drawMissionInfo();
  drawEquipmentSection();
  drawPressureGauge();
  drawSmartFeedback();
  drawCrosshair(crosshairPos.x, crosshairPos.y, sprayRadius);
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








void keyPressed() {
  // 數字鍵 1, 2, 3 切換藥劑 (模擬硬體切換) - 加入冷卻時間
  int now = millis();
  if (now - lastAgentSwitch > agentSwitchCooldown) {
    if (key == '1') {
      currentAgent = Agent.WATER;
      lastAgentSwitch = now;
    } else if (key == '2') {
      currentAgent = Agent.POWDER;
      lastAgentSwitch = now;
    } else if (key == '3') {
      currentAgent = Agent.CO2;
      lastAgentSwitch = now;
    }
  }
  
  if (key == 'r' || key == 'R') {
    // 重新開始
    currentState = State.START;
    fireHealth = 100;
    extinguisherPressure = 100;
    remainingTime = 180;
    // 重新隨機火源位置
    firePos = new PVector(random(200, width-200), random(height*0.5, height*0.9));
    particles.clear();
    fireParticles.clear(); // 清理火焰粒子
  } else if (currentState == State.START) {
    // 開始遊戲
    currentState = State.PLAYING;
    lastTimeUpdate = millis();
  }
}
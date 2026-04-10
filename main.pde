/**
 * Firefighting Training System - Core Logic
 * Language: Processing (Java-based)
 */
 
 
//新增:音效
import processing.sound.*;
SoundFile bgm;
SoundFile waterSfx;

// 系統狀態定義
enum State { START, SELECT_MISSION, PLAYING, RESULT }
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

// 任務配置結構
class Mission {
  String name;
  FireType type;
  int timeLimit;
  float initialHealth;
  String description;

  Mission(String n, FireType t, int time, float hp, String desc) {
    name = n; type = t; timeLimit = time; initialHealth = hp; description = desc;
  }
}

Mission[] missions;


//新加:圖片
PImage[] missionPics = new PImage[5];
PImage[][] furniturePics = new PImage[5][5];      // 5個任務，每個任務5個家具
PVector[][] furniturePositions = new PVector[5][5]; // 紀錄每個家具的 X, Y 座標
// 新增：集中管理 25 個家具的精確座標 {X, Y}
// 結構為：manualCoords[任務編號][家具編號][0是X, 1是Y]
float[][][] manualCoords = {
  // 任務 0 (pic0) 的 5 個家具座標 {x, y}
  { {880, 400}, {300, 176}, {650, 400}, {500, 600}, {110, 450} },
  
  // 任務 1 (pic1) 的 5 個家具座標
  { {850, 250}, {1140, 410}, {650, 400}, {200, 100}, {120, 400} },
  
  // 任務 2 (pic2) 的 5 個家具座標
  { {136, 476}, {300, 350}, {550, 300}, {1100, 476}, {750, 300} },
  
  // 任務 3 (pic3) 的 5 個家具座標
  { {1150, 300}, {150, 226}, {1000, 450}, {750, 500}, {300, 450} },
  
  // 任務 4 (pic4) 的 5 個家具座標
  { {250, 500}, {500, 520}, {850, 550}, {400, 350}, {980, 380} }
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
  missions[0] = new Mission("普通火災演練", FireType.GENERAL, 120, 100, "撲滅A類普通火災（木材、紙張）");
  missions[1] = new Mission("電器火災挑戰", FireType.ELECTRICAL, 90, 80, "電氣火災嚴禁使用水基滅火劑");
  missions[2] = new Mission("油類火災挑戰", FireType.GENERAL, 60, 150, "撲滅B類油類火災");
  missions[3] = new Mission("金屬火災演練", FireType.ELECTRICAL, 80, 120, "高難度:涉及活性金屬，禁水性物質");
  missions[4] = new Mission("緊急複合演練", FireType.GENERAL, 150, 200, "高難度：氣爆後火勢蔓延極快");

  // ---> 關鍵修改：載入 5 張圖片 <---
  missionPics[0] = loadImage("pic0.jpg"); 
  missionPics[1] = loadImage("pic1.jpg");
  missionPics[2] = loadImage("pic2.jpg");
  missionPics[3] = loadImage("pic3.jpg"); // 新增
  missionPics[4] = loadImage("pic4.jpg"); // 新增
  
  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 5; j++) {
      // 載入圖片 (01.png ~ 45.png)
      String fileName = nf(i * 10 + (j + 1), 2) + ".png"; 
      furniturePics[i][j] = loadImage(fileName);
      
      // ---> 關鍵修改：讀取我們手動設定好的陣列座標 <---
      float x = manualCoords[i][j][0];
      float y = manualCoords[i][j][1];
      furniturePositions[i][j] = new PVector(x, y);
    }
  }

  firePos = new PVector(random(200, width-200), random(height*0.5, height*0.9));
  targetPos = new PVector(width/2, height/2);
  crosshairPos = new PVector(width/2, height/2);
}

void draw() {
  background(30);
  
  switch(currentState) {
    case START: drawStartScreen(); break;
    case SELECT_MISSION: drawMissionSelectScreen(); break; // 新增狀態
    case PLAYING: updateSimulation(); drawGameUI(); break;
    case RESULT: drawResultScreen(); break;
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
    
    if (!waterSfx.isPlaying()) {
      waterSfx.play(); 
    }
  }else {
    // ---> 新增：沒有按壓（或沒壓力了）時，馬上停止播放 <---
    if (waterSfx.isPlaying()) {
      waterSfx.stop();
    }
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
  
  //新加的
  drawpictures();
  
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


/**
 * 處理鍵盤輸入邏輯：支援狀態切換、任務選擇與藥劑控制
 */
void keyPressed() {
  int now = millis();

  if (key == 'r' || key == 'R') {
    resetToStart();
    return;
  }

  switch (currentState) {
    case START:
      currentState = State.SELECT_MISSION;
      break;

    case SELECT_MISSION:
      if (keyCode == UP) {
        selectedMissionIdx = (selectedMissionIdx - 1 + missions.length) % missions.length;
      } 
      else if (keyCode == DOWN) {
        selectedMissionIdx = (selectedMissionIdx + 1) % missions.length;
      } 
      else if (key == ENTER) {
        initializeSelectedMission();
        currentState = State.PLAYING;
        lastTimeUpdate = millis();
        
       
        if (bgm.isPlaying()) {
          bgm.stop();
        }
        
      }
      break;

    case PLAYING:
      // 藥劑切換邏輯
      if (now - lastAgentSwitch > agentSwitchCooldown) {
        if (key == '1') { currentAgent = Agent.WATER; lastAgentSwitch = now; }
        else if (key == '2') { currentAgent = Agent.POWDER; lastAgentSwitch = now; }
        else if (key == '3') { currentAgent = Agent.CO2; lastAgentSwitch = now; }
      }
      break;
  }
}

/**
 * 輔助函數：初始化所選任務的參數
 */
void initializeSelectedMission() {
  Mission m = missions[selectedMissionIdx];
  currentFireType = m.type;
  remainingTime = m.timeLimit;
  fireHealth = m.initialHealth;
  extinguisherPressure = 100.0f; 
  
  // ---> 關鍵修改：從該任務的 5 個家具中，隨機抽選一個作為起火點 <---
  // random(5) 會產生 0.0 ~ 4.999 的小數，用 int() 轉換後就會變成 0, 1, 2, 3, 4
  int randomIdx = int(random(5)); 
  
  // 取得抽中的家具 X, Y 座標
  float targetX = manualCoords[selectedMissionIdx][randomIdx][0];
  float targetY = manualCoords[selectedMissionIdx][randomIdx][1];
  
  // 設定火源位置 (小技巧：Y 軸稍微扣掉一點數值，讓火源看起來是從家具"上方"燒起來的，而不是被家具擋住一半)
  firePos = new PVector(targetX, targetY - 30); 
  
  // 清理殘留粒子
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

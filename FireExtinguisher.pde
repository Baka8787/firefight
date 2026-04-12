/**
 * FireExtinguisher.pde
 * 噴嘴視覺、軟管繪製、粒子生成與藥劑顏色
 */ 

/**
 * 繪製滅火器工具（第一人稱視角）
 */
void drawFireExtinguisher() {
  pushStyle();

  // 1. 握持點：X 中幅跟隨，Y 微幅跟隨
  float holdX = width * 0.5 + (mouseX - width * 0.5) * 0.18;
  float holdY = (height - 80) + (mouseY - height * 0.5) * 0.06;
  holdY = constrain(holdY, height - 130, height - 30);

  lerpNozzleX = lerp(lerpNozzleX, holdX, 0.10);
  lerpNozzleY = lerp(lerpNozzleY, holdY, 0.10);

  // 2. 瓶身接點：靠近中間，X 跟隨幅度比噴嘴小（重量感）
  float tankOffsetX = (mouseX - width * 0.5) * 0.04;
  float tankAttachX = width * 0.55 + tankOffsetX;
  float tankAttachY = height + 30;

  // 3. 繪製軟管（雙層渲染增加立體感）
  noFill();
  stroke(10);
  strokeWeight(16);
  bezier(tankAttachX, tankAttachY,
         tankAttachX,        tankAttachY - 100,
         lerpNozzleX + 30,   lerpNozzleY + 80,
         lerpNozzleX,        lerpNozzleY);
  stroke(50);
  strokeWeight(8);
  bezier(tankAttachX, tankAttachY,
         tankAttachX,        tankAttachY - 100,
         lerpNozzleX + 30,   lerpNozzleY + 80,
         lerpNozzleX,        lerpNozzleY);

  // 4. 噴嘴朝向準心旋轉
  pushMatrix();
  translate(lerpNozzleX, lerpNozzleY);

  float angle = atan2(crosshairPos.y - lerpNozzleY, crosshairPos.x - lerpNozzleX);
  float breathe = sin(frameCount * 0.05) * 1.5;
  rotate(angle + radians(breathe));

  if (currentAgent == Agent.CO2) {
    drawCO2Horn();
  } else {
    drawStandardNozzle();
  }

  popMatrix();
  popStyle();
}

/**
 * 標準直管噴嘴（水／乾粉）
 */
void drawStandardNozzle() {
  fill(160, 0, 0);
  rect(-40, -12, 50, 24, 5); // 握柄
  fill(40);
  rect(10, -8, 40, 16, 2);   // 噴嘴管
}

/**
 * CO2 喇叭狀噴嘴
 */
void drawCO2Horn() {
  fill(40);
  noStroke();
  beginShape();
  vertex(0, -5);
  vertex(50, -20);
  vertex(50, 20);
  vertex(0, 5);
  endShape(CLOSE);
  fill(80);
  rect(-20, -10, 25, 20, 3); // 握把
}

/**
 * 從噴嘴前端生成滅火粒子
 */
void generateParticles(PVector target, float radius) {
  float muzzleLength = (currentAgent == Agent.CO2) ? 50 : 40;
  float angle = atan2(mouseY - lerpNozzleY, mouseX - lerpNozzleX);
  float emitX = lerpNozzleX + cos(angle) * muzzleLength;
  float emitY = lerpNozzleY + sin(angle) * muzzleLength;
  PVector emitPos = new PVector(emitX, emitY);

  if (isPressing()) {
    // 增加噴射時的視覺後座力抖動
    lerpNozzleY = lerp(lerpNozzleY, height - 60 + random(10, 15), 0.4);
  }

float gravity, drag, flightFrames, spreadMult;
  
  if (currentAgent == Agent.POWDER) {
    gravity = 0.03; drag = 0.97; flightFrames = 35; spreadMult = 1.8;
  } else if (currentAgent == Agent.CO2) {
    // 調整 CO2 物理參數
    gravity = 0.01; 
    drag = 0.96;         // 稍微提高 drag (阻力變小)，讓氣體飛得更遠
    flightFrames = 30;   // 與 Particle 建構子對齊
    spreadMult = 3.0;    // 增加散射，讓雲團更寬
    
  // ---> 關鍵新增：加上 METAL 藥劑的物理特性 <---
  } else if (currentAgent == Agent.METAL) {
    gravity = 0.05; drag = 0.965; flightFrames = 32; spreadMult = 1.5;
    
  } else {
    // 預設 (WATER 水)
    gravity = 0.28; drag = 0.985; flightFrames = 38; spreadMult = 1.2;
  }

  // 數量優化：減少單次生成的倍數，改由單個粒子更大的雲團補償，解決卡頓
  int baseCount = int(map(extinguisherPressure, 0, 100, 2, 6));
  int finalCount = baseCount;
  if (currentAgent == Agent.CO2) finalCount = baseCount * 2; // 從 3 倍降為 2 倍，減少計算量

  for (int i = 0; i < finalCount; i++) {
    float vVar = random(0.85, 1.15); // 增加速度變異，讓消散更有層次
    float spreadX = random(-spreadMult, spreadMult);
    float spreadY = random(-spreadMult * 0.7, spreadMult * 0.7);
    
    // 計算初始速度
    float dragSum = (1.0 - pow(drag, flightFrames)) / (1.0 - drag);
    float vx0 = (target.x - emitPos.x) / dragSum;
    float gravityContrib = gravity * dragSum * flightFrames * 0.55;
    float vy0 = ((target.y - emitPos.y) - gravityContrib) / dragSum;

    particles.add(new Particle(emitPos.copy(), new PVector(vx0 * vVar + spreadX, vy0 * vVar + spreadY), getAgentColor()));
  }
}

/**
 * 根據當前藥劑回傳對應顏色
 */
color getAgentColor() {
  switch(currentAgent) {
    case WATER:  return color(100, 200, 255, 150);
    case POWDER: return color(240, 240, 200, 180);
    case CO2:    return color(255, 255, 255, 100);
    // ---> 新增：金屬滅火粉末設定為帶點灰黃色的特製粉末 <---
    case METAL:  return color(210, 200, 170, 200); 
    default:     return color(255);
  }
}

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
    lerpNozzleY = lerp(lerpNozzleY, height - 60 + 12, 0.4);
  }

  float gravity, drag, flightFrames, spreadMult;
  if (currentAgent == Agent.POWDER) {
    gravity      = 0.04;
    drag         = 0.96;
    flightFrames = 35;
    spreadMult   = 1.0;
  } else if (currentAgent == Agent.CO2) {
    gravity      = 0.02;
    drag         = 0.94;
    flightFrames = 28;
    spreadMult   = 0.6;
  } else {
    gravity      = 0.28;
    drag         = 0.985;
    flightFrames = 38;
    spreadMult   = 1.2;
  }

  float dragSum = (1.0 - pow(drag, flightFrames)) / (1.0 - drag);
  float dx = target.x - emitPos.x;
  float vx0 = dx / dragSum;

  float gravityBias = 0.5; // 落點偏下就調小，偏上就調大
  float gravityContrib = gravity * dragSum * flightFrames * gravityBias;
  float dy = target.y - emitPos.y;
  float vy0 = (dy - gravityContrib) / dragSum;

  // 動態 lifespan
//   float travelDist = dist(emitPos.x, emitPos.y, target.x, target.y);
//   float decayRate = (currentAgent == Agent.CO2) ? 5.0 : 
//                     (currentAgent == Agent.POWDER) ? 2.5 : 3.5;
//   float targetLifespan = flightFrames * decayRate;
//   targetLifespan *= map(travelDist, 0, dist(0, 0, width, height), 0.6, 1.4);
//   targetLifespan = constrain(targetLifespan, 60, 400);

  int count = int(map(extinguisherPressure, 0, 100, 2, 6));
  for (int i = 0; i < count; i++) {
    float spreadX = random(-spreadMult, spreadMult);
    float spreadY = random(-spreadMult * 0.5, spreadMult * 0.5);
    PVector v = new PVector(vx0 + spreadX, vy0 + spreadY);
    particles.add(new Particle(emitPos.copy(), v, getAgentColor()));
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
    default:     return color(255);
  }
}

/**
 * FireSim.pde
 * 火焰模擬、滅火判定、螢幕震動
 */

/**
 * 繪製火焰視覺效果（粒子系統）
 */
void drawFire() {
  pushStyle();
  blendMode(ADD);
  for (FireParticle fp : fireParticles) {
    fp.display();
  }
  blendMode(BLEND);
  popStyle();
}

/**
 * 繪製火源底座參考橢圓
 */
void drawFireBase() {
  pushStyle();
  fill(0, 50);
  noStroke();
  ellipse(firePos.x, firePos.y,
          150 * (fireHealth / 100.0f),
          40  * (fireHealth / 100.0f));
  popStyle();
}

/**
 * 更新火焰粒子系統（生成 + 更新 + 清除）
 */
void updateFireParticles() {
  float spawnRate = map(fireHealth, 0, 100, 0, 22.0f);
  float fireWidth = map(fireHealth, 0, 100, 0, 170);

  if (random(10) < spawnRate && fireParticles.size() < MAX_FIRE_PARTICLES) {
    float xOffset = randomGaussian() * (fireWidth / 5);
    PVector fireBase = new PVector(firePos.x + xOffset, firePos.y);
    fireParticles.add(new FireParticle(fireBase));
  }

  for (int i = fireParticles.size() - 1; i >= 0; i--) {
    FireParticle fp = fireParticles.get(i);
    fp.update();
    if (fp.isDead()) fireParticles.remove(i);
  }
}


// === FireSim.pde ===

void checkExtinguishByCrosshair() {
  float d = dist(crosshairPos.x, crosshairPos.y, firePos.x, firePos.y);
  float aimRadius = sprayRadius * 0.8;
  if (d > aimRadius) return;

  // 1. 距離衰減與高度判定 (維持原樣)
  float distFactor = pow(1.0 - (d / aimRadius), 1.5);
  float heightPenalty = 0.4;
  if (crosshairPos.y >= firePos.y - 30 && crosshairPos.y <= firePos.y + 30) heightPenalty = 1.0;
  else if (crosshairPos.y < firePos.y - 30) heightPenalty = 0.1;

  // ---> 2. 藥劑匹配邏輯 (完全依照您的設定) <---
  float effectiveMult = 0.0; // 0 代表無效或懲罰，大於 0 代表有效

  switch(currentFireType) {
    case GENERAL:
      // GENERAL 只能用 WATER, POWDER
      if (currentAgent == Agent.WATER || currentAgent == Agent.POWDER) effectiveMult = 1.0;
      break;
      
    case ELECTRICAL:
      // ELECTRICAL 只能用 WATER, CO2 (依照您的指示)
      if (currentAgent == Agent.WATER || currentAgent == Agent.CO2) effectiveMult = 1.0;
      else effectiveMult = -0.5; // 用錯藥劑稍微扣分(火勢變大)
      break;
      
    case OIL:
      // OIL 只能用 WATER, CO2 (依照您的指示)
      if (currentAgent == Agent.WATER || currentAgent == Agent.CO2) effectiveMult = 1.0;
      break;
      
    case METAL:
      // METAL 只能用 METAL
      if (currentAgent == Agent.METAL) effectiveMult = 1.0;
      break;
  }

  // 3. 計算最終傷害並扣血
  // 如果 effectiveMult > 0，則根據距離和高度造成傷害；否則造成負面效果或 0
  float baseDamage = 0.7;
  float finalDamage = baseDamage * effectiveMult * distFactor * heightPenalty;
  
  fireHealth = constrain(fireHealth - finalDamage, 0, 100);
  
  // 如果用錯藥劑導致傷害是負的，可以觸發震動提示玩家
  if (finalDamage < 0) {
    shakeScreen();
  }
}

/**
 * 螢幕震動效果（錯誤藥劑或緊急情況觸發）
 */
void shakeScreen() {
  pushMatrix();
  translate(random(-3, 3), random(-3, 3));
  popMatrix();
}

void drawFireDebug() {
  if (!debugMode) return;
  
  pushStyle();
  noFill();
  // 繪製判定圓圈 (判定半徑) 
  stroke(255, 0, 0, 150); 
  float aimRadius = sprayRadius * 0.8;
  ellipse(firePos.x, firePos.y, aimRadius * 2, aimRadius * 2);
  
  // 繪製高度有效區間 [cite: 74-75]
  stroke(0, 255, 255, 100);
  line(0, firePos.y - 30, width, firePos.y - 30);
  line(0, firePos.y + 30, width, firePos.y + 30);
  
  // 顯示當前數值
  fill(255);
  textSize(14);
  text("Debug: FireHealth " + nf(fireHealth, 0, 2), firePos.x + 80, firePos.y);
  popStyle();
}


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


void checkExtinguishByCrosshair() {
  float d = dist(crosshairPos.x, crosshairPos.y, firePos.x, firePos.y);

  // 準心必須在這個範圍內才算對準
  float aimRadius = sprayRadius * 0.8;
  if (d > aimRadius) return; // 沒對準，直接不造成傷害

  // 距離衰減：正中心傷害最高
  float distFactor = 1.0 - (d / aimRadius);
  distFactor = pow(distFactor, 1.5); // 稍微收斂，避免邊緣太容易觸發

  // 根部判定：準心 Y 軸要接近火源根部
  float heightPenalty;
  if (crosshairPos.y >= firePos.y - 30 && crosshairPos.y <= firePos.y + 30) {
    heightPenalty = 1.0;  // 根部命中
  } else if (crosshairPos.y < firePos.y - 30) {
    heightPenalty = 0.1;  // 打太高，幾乎無效
  } else {
    heightPenalty = 0.4;  // 打太低
  }

  // 藥劑匹配
  float damage;
  if (currentFireType == FireType.ELECTRICAL && currentAgent == Agent.WATER) {
    damage = -0.3 * distFactor; // 懲罰
  } else if (currentAgent == Agent.POWDER) {
    damage = 0.5 * distFactor * heightPenalty;
  } else if (currentAgent == Agent.CO2) {
    float baseEff = (currentFireType == FireType.ELECTRICAL) ? 1.0 : 0.45;
    damage = baseEff * distFactor * heightPenalty;
  } else {
    damage = 0.7 * distFactor * heightPenalty;
  }

  fireHealth = constrain(fireHealth - damage, 0, 100);
}

/**
 * 螢幕震動效果（錯誤藥劑或緊急情況觸發）
 */
void shakeScreen() {
  pushMatrix();
  translate(random(-3, 3), random(-3, 3));
  popMatrix();
}
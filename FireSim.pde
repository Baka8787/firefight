
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

/**
 * 強化後的滅火效率判定（含錯誤藥劑懲罰）
 * 注意：目前由 Particle.checkFireCollision() 主導傷害，
 * 此函式保留供外部直接呼叫使用
 */
void checkExtinguishEffect(PVector pos, float radius) {
  float d = dist(pos.x, pos.y, firePos.x, firePos.y);
  float efficiency = map(radius, 20, 150, 1.2, 0.3);

  // 根部判定：瞄準過高效率降為 10%
  if (pos.y > firePos.y + 20) efficiency *= 0.1;

  float damage = 0;
  if (currentFireType == FireType.ELECTRICAL && currentAgent == Agent.WATER) {
    damage = -0.2;
    shakeScreen();
  } else {
    if (d < radius + 60) damage = efficiency * 0.8;
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
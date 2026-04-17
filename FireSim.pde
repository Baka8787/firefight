/**
 * FireSim.pde
 * 進階火焰模擬：包含多點蔓延、根部判定優化、與環境引燃邏輯
 */

// 火源點清單（由任務初始化時填入家具座標）
ArrayList<FireSource> fireSources = new ArrayList<FireSource>();

/**
 * 火源點類別：定義單一起火位置的狀態
 */
class FireSource {
  PVector pos;
  float health;
  FireType type;
  boolean active;
  float spawnTimer = 0;

  FireSource(PVector p, FireType t, boolean startActive) {
    this.pos = p.copy();
    this.type = t;
    this.active = startActive;
    this.health = startActive ? 100.0f : 0.0f;
  }

  void update() {
    if (!active) return;

    // 1. 自然成長：如果沒在滅火，火勢會緩慢變大
    if (health < 100 && health > 0) {
      health += 0.02; 
    }

    // 2. 蔓延判定：如果火勢大於 60%，有機率引燃鄰近點
    if (health > 60) {
      checkSpread(this);
    }
    
    // 3. 熄滅判定
    if (health <= 0) {
      active = false;
      health = 0;
    }
  }

  void display() {
    if (!active || health <= 0) return;
    
    // 生成該點的火焰粒子
    float spawnRate = map(health, 0, 100, 0, 15.0f);
    if (random(10) < spawnRate && fireParticles.size() < MAX_FIRE_PARTICLES) {
      float fireWidth = map(health, 0, 100, 0, 150);
      float xOffset = randomGaussian() * (fireWidth / 6);
      fireParticles.add(new FireParticle(new PVector(pos.x + xOffset, pos.y)));
    }
    
    // 繪製底座陰影 [cite: 66]
    pushStyle();
    fill(0, 40);
    noStroke();
    ellipse(pos.x, pos.y, 120 * (health / 100.0f), 30 * (health / 100.0f));
    popStyle();
  }
}

/**
 * 核心：更新所有火源點與蔓延
 */
void updateFireSystem() {
  for (FireSource fs : fireSources) {
    fs.update();
  }
  
  // 更新火焰粒子視覺
  for (int i = fireParticles.size() - 1; i >= 0; i--) {
    FireParticle fp = fireParticles.get(i);
    fp.update();
    if (fp.isDead()) fireParticles.remove(i);
  }

  // 同步全域變數 (為了相容舊 UI 顯示)
  if (fireSources.size() > 0) {
    float totalHealth = 0;
    for (FireSource fs : fireSources) totalHealth += fs.health;
    fireHealth = totalHealth / fireSources.size();
  }
}

/**
 * 繪製所有火焰粒子
 */
void drawFire() {
  pushStyle();
  blendMode(ADD);
  for (FireSource fs : fireSources) {
    fs.display(); // 讓每個火源生成自己的粒子
  }
  for (FireParticle fp : fireParticles) {
    fp.display();
  }
  blendMode(BLEND);
  popStyle();
}

/**
 * 蔓延邏輯：檢查鄰近的未起火點
 */
void checkSpread(FireSource source) {
  for (FireSource target : fireSources) {
    if (!target.active) {
      float d = dist(source.pos.x, source.pos.y, target.pos.x, target.pos.y);
      // 距離 250 像素內且機率觸發
      if (d < 250 && random(1000) < 1) { 
        target.active = true;
        target.health = 5; // 從小火開始引燃
      }
    }
  }
}

/**
 * 滅火判定：包含根部判定優化
 */
void checkExtinguishByCrosshair() {
  // 找出離準心最近的火源
  FireSource targetSource = null;
  float minDist = 9999;
  
  for (FireSource fs : fireSources) {
    if (!fs.active) continue;
    float d = dist(crosshairPos.x, crosshairPos.y, fs.pos.x, fs.pos.y);
    if (d < minDist) {
      minDist = d;
      targetSource = fs;
    }
  }

  if (targetSource == null || minDist > sprayRadius * 1.2) return;

  // 1. 距離與高度判定 (比照現實優化) [cite: 74-76]
  float d = dist(crosshairPos.x, crosshairPos.y, targetSource.pos.x, targetSource.pos.y);
  float aimRadius = sprayRadius * 0.9;
  float distFactor = pow(constrain(1.0 - (d / aimRadius), 0, 1), 1.2);
  
  // 高度判定：瞄準根部 (pos.y) 效率最高，往上偏移則遞減
  float yDiff = targetSource.pos.y - crosshairPos.y; 
  float heightFactor = 0.05; // 預設極低 (瞄準火焰上方)
  
  if (yDiff >= -20 && yDiff <= 40) {
    heightFactor = 1.0; // 核心根部區間
  } else if (yDiff > 40) {
    heightFactor = map(yDiff, 40, 150, 0.8, 0.1); // 往上偏移效率遞減
    heightFactor = constrain(heightFactor, 0.1, 0.8);
  }

  // 2. 藥劑匹配邏輯 (保持您的設定) [cite: 77-82]
  float agentMult = 0.0;
  switch(currentFireType) {
    case GENERAL:
      if (currentAgent == Agent.WATER || currentAgent == Agent.POWDER) agentMult = 1.0;
      break;
    case ELECTRICAL:
      if (currentAgent == Agent.WATER || currentAgent == Agent.CO2) agentMult = 1.2;
      else agentMult = -0.6; // 用錯藥劑助長火勢
      break;
    case OIL:
      if (currentAgent == Agent.WATER || currentAgent == Agent.CO2) agentMult = 1.0;
      else agentMult = -0.8;
      break;
    case METAL:
      if (currentAgent == Agent.METAL) agentMult = 1.5;
      else agentMult = -1.0; // 金屬火災遇水會爆炸
      break;
  }

  // 3. 施加傷害
  float finalDamage = 0.8 * agentMult * distFactor * heightFactor;
  targetSource.health = constrain(targetSource.health - finalDamage, 0, 100);
  
  if (finalDamage < 0) shakeScreen();
}

void shakeScreen() {
  pushMatrix();
  translate(random(-5, 5), random(-5, 5));
  popMatrix();
}

void drawFireDebug() {
  if (!debugMode) return;
  pushStyle();
  for (FireSource fs : fireSources) {
    noFill();
    stroke(fs.active ? #FF0000 : #00FF00, 150);
    ellipse(fs.pos.x, fs.pos.y, sprayRadius * 1.8, sprayRadius * 1.8);
    
    fill(255);
    textSize(12);
    text(int(fs.health) + "%", fs.pos.x - 10, fs.pos.y + 5);
    if (fs.active) {
      stroke(0, 255, 255, 100);
      line(fs.pos.x - 50, fs.pos.y - 20, fs.pos.x + 50, fs.pos.y - 20);
      line(fs.pos.x - 50, fs.pos.y + 40, fs.pos.x + 50, fs.pos.y + 40);
    }
  }
  popStyle();
}
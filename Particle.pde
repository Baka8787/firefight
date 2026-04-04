class Particle {
  PVector p, v, prevP; // 增加 prevP 用於繪製速度線段
  float lifespan;
  color c;
  float initialSize;
  float driftSeed; // 隨機漂移種子
  boolean hasCollided = false;

  Particle(PVector p, PVector v, color c) {
    this.p = p.copy();
    this.prevP = p.copy();
    this.v = v.copy();
    this.c = c;
    this.lifespan = 255;
    this.driftSeed = random(1000);
    this.initialSize = (currentAgent == Agent.POWDER) ? random(5, 8) : 10;
  }

    void update() {
    prevP.set(p);

    if (currentAgent == Agent.WATER) {
        v.y += 0.28;       // 與 generateParticles gravity 一致
        v.mult(0.985);     // 與 drag 一致

    } else if (currentAgent == Agent.POWDER) {
        v.y += 0.04;       // 一致
        v.mult(0.96);      // 一致
        // 布朗運動保留，但幅度縮小避免偏離落點太多
        float noiseX = (noise(driftSeed, frameCount * 0.05) - 0.5) * 0.5;
        v.x += noiseX;

    } else if (currentAgent == Agent.CO2) {
        v.y += 0.02;       // 一致（原本是 v.y -= 0.02，改為微幅下墜）
        v.mult(0.94);      // 一致
        initialSize = 12;
    }

    p.add(v);

    if (currentAgent == Agent.CO2) {
        lifespan -= 5.0;
    } else if (currentAgent == Agent.POWDER) {
        lifespan -= 2.5;
    } else {
        lifespan -= 3.5;
    }

    // 粒子碰撞判定已移除，傷害由準心決定
    }

  void display() {
    float alpha = map(lifespan, 255, 0, 180, 0);
    pushStyle();
    
    if (currentAgent == Agent.WATER) {
      stroke(c, alpha);
      strokeWeight(map(lifespan, 255, 0, initialSize, 1));
      line(p.x, p.y, prevP.x, prevP.y); 
    } else if (currentAgent == Agent.POWDER) {
      noStroke();
      float sz = map(lifespan, 255, 0, initialSize, initialSize * 5);

      // 外層柔和粉塵雲
      fill(c, alpha * 0.4);
      ellipse(p.x, p.y, sz + random(-2, 2), sz + random(-2, 2));

      // 核心顆粒
      fill(c, alpha * 0.8);
      ellipse(p.x + random(-1.5, 1.5), p.y + random(-1.5, 1.5), sz * 0.4, sz * 0.4);
    } else if (currentAgent == Agent.CO2) {
      noStroke();
      float sz = map(lifespan, 255, 0, 10, 60);
      fill(255, alpha * 0.6);
      ellipse(p.x, p.y, sz, sz);
      if (random(1) > 0.8) {
        fill(200, 230, 255, alpha);
        rect(p.x, p.y, 2, 2);
      }
    } else {
      noStroke();
      fill(c, alpha);
      ellipse(p.x, p.y, 8, 8);
    }

    popStyle();
  }

  void checkFireCollision() {
    float hitDist = dist(p.x, p.y, firePos.x, firePos.y);
    
    // 縮小有效半徑，要求更精準的瞄準
    float effectiveRadius;
    if (currentAgent == Agent.POWDER) {
      effectiveRadius = 80;  // 原本 200
    } else if (currentAgent == Agent.CO2) {
      effectiveRadius = 60;  // CO2 要求最精準
    } else {
      effectiveRadius = 50;  // 水柱最集中
    }
  
    if (hitDist < effectiveRadius) {
      float distFactor;
      
      // 距離衰減改用平方，邊緣效果大幅降低，核心命中才有明顯效果
      float normalized = hitDist / effectiveRadius; // 0(正中心) ~ 1(邊緣)
      distFactor = 1.0 - (normalized * normalized); // 平方衰減
      distFactor = constrain(distFactor, 0, 1);
      
      applyExtinguishLogic(distFactor);
      hasCollided = true;
    }
  }

    void applyExtinguishLogic(float distFactor) {
        // 根部判定：粒子打到火源上半部效率大幅降低
        float heightPenalty = 1.0;
        if (p.y < firePos.y - 20) {       // 打太高
            heightPenalty = 0.15;
        } else if (p.y < firePos.y + 10) { // 根部附近（最佳）
            heightPenalty = 1.0;
        } else {
            heightPenalty = 0.5;             // 打太低
        }

        float damage;
        if (currentFireType == FireType.ELECTRICAL && currentAgent == Agent.WATER) {
            damage = -0.4 * distFactor;
        } else if (currentAgent == Agent.POWDER) {
            damage = 0.55 * distFactor * heightPenalty;
        } else if (currentAgent == Agent.CO2) {
            float baseEff = (currentFireType == FireType.ELECTRICAL) ? 1.2 : 0.6;
            damage = baseEff * pow(distFactor, 2) * heightPenalty;
        } else {
            damage = 0.8 * distFactor * heightPenalty;
        }
        fireHealth = constrain(fireHealth - damage, 0, 100);
    }

  boolean isDead() { return lifespan <= 0; }
}

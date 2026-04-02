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
    prevP.set(p); // 記錄當前位置
    
    if (currentAgent == Agent.WATER) {
      v.y += 0.28;
      v.mult(0.985);
    } else if (currentAgent == Agent.POWDER) {
        v.mult(0.96); // 原本 0.92，阻力放輕讓粒子飛更遠
        v.y += 0.04;
        float noiseX = (noise(driftSeed, frameCount * 0.05) - 0.5) * 0.9;
        v.x += noiseX;
        v.x += (noise(driftSeed + 100, frameCount * 0.03) - 0.5) * 0.4;
    } else if (currentAgent == Agent.CO2) {
      // CO2 物理：噴射後擴散並受熱氣流上升影響
      v.mult(0.94);
      v.y -= 0.02;
      initialSize = 12;
    }

    p.add(v);

    // 生命週期調整：CO2 最快、乾粉最長、水在中間
    if (currentAgent == Agent.CO2) {
      lifespan -= 5.0;
    } else if (currentAgent == Agent.POWDER) {
      lifespan -= 2.5;
    } else {
      lifespan -= 3.5;
    }

    if (!hasCollided && lifespan > 0) {
      checkFireCollision();
    }
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
    // 使用動態 firePos 檢測火源範圍，並加入相對效率
    float hitDist = dist(p.x, p.y, firePos.x, firePos.y);
    float effectiveRadius = (currentAgent == Agent.POWDER) ? 200 : 95; // 乾粉範圍更大

    if (hitDist < effectiveRadius) {
      float distFactor;
      if (currentAgent == Agent.POWDER) {
        distFactor = map(hitDist, 0, effectiveRadius, 1.0, 0.6);
      } else {
        distFactor = map(hitDist, 0, effectiveRadius, 1.0, 0.3);
      }
      distFactor = constrain(distFactor, 0, 1);
      applyExtinguishLogic(distFactor);
      hasCollided = true;
    }
  }

  void applyExtinguishLogic(float distFactor) {
    float damage;
    if (currentFireType == FireType.ELECTRICAL && currentAgent == Agent.WATER) {
      damage = -0.4 * distFactor;
    } else if (currentAgent == Agent.POWDER) {
      damage = 0.35 * distFactor;
    } else if (currentAgent == Agent.CO2) {
      float baseEff = (currentFireType == FireType.ELECTRICAL) ? 0.9 : 0.4;
      damage = baseEff * pow(distFactor, 2);
    } else {
      damage = 0.6 * distFactor;
    }
    fireHealth = constrain(fireHealth - damage, 0, 100);
  }

  boolean isDead() { return lifespan <= 0; }
}

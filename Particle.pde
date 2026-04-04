class Particle {
  PVector p, v, prevP;
  float lifespan;
  float lifespanDecay;
  color c;
  float initialSize;
  float driftSeed;
  boolean hasCollided = false;

  // 預算偏移值，避免 display() 內頻繁 random()
  float splashOffsetX, splashOffsetY, splashSize;
  float mistOffsetX, mistOffsetY;

  Particle(PVector p, PVector v, color c) {
    this.p = p.copy();
    this.prevP = p.copy();
    this.v = v.copy();
    this.c = c;
    this.driftSeed = random(1000);
    this.hasCollided = false;

    if (currentAgent == Agent.POWDER) {
      this.initialSize = random(5, 8);
    } else if (currentAgent == Agent.CO2) {
      this.initialSize = 12;
    } else {
      this.initialSize = random(6, 14);
    }

    if (currentAgent == Agent.WATER) {
      this.lifespanDecay = 255.0 / 38.0;
    } else if (currentAgent == Agent.POWDER) {
      this.lifespanDecay = 255.0 / 33.0;
    } else {
      this.lifespanDecay = 255.0 / 26.0;
    }

    this.lifespan = 255;

    // 預算所有 display() 需要的隨機偏移，固定不閃爍
    this.splashOffsetX = random(-1.2, 1.2);
    this.splashOffsetY = random(-0.8, 0.8);
    this.splashSize    = random(0.2, 0.8);
    this.mistOffsetX   = random(-6, 6);
    this.mistOffsetY   = random(-6, 6);
  }

  void update() {
    prevP.set(p);

    if (currentAgent == Agent.WATER) {
      v.y += 0.28;
      v.mult(0.985);

    } else if (currentAgent == Agent.POWDER) {
      v.y += 0.04;
      v.mult(0.96);
      float noiseX = (noise(driftSeed, frameCount * 0.05) - 0.5) * 0.5;
      v.x += noiseX;

    } else if (currentAgent == Agent.CO2) {
      v.y += 0.02;
      v.mult(0.94);
    }

    p.add(v);
    lifespan -= lifespanDecay;
  }

  void display() {
    float alpha = map(lifespan, 255, 0, 180, 0);
    pushStyle();

    if (currentAgent == Agent.WATER) {
      float lifeRatio = lifespan / 255.0;
      float w = map(lifespan, 255, 0, initialSize * 1.8, initialSize * 0.5);

      // 水色：深藍 → 淡白水霧
      color deepBlue  = color(60, 150, 255, alpha);
      color mistWhite = color(200, 230, 255, alpha * 0.4);
      color waterCol  = lerpColor(deepBlue, mistWhite, 1.0 - lifeRatio);

      // 主水柱線段
      stroke(waterCol);
      strokeWeight(w);
      line(p.x, p.y, prevP.x, prevP.y);

      // 水花：固定偏移，不閃爍
      if (splashSize > 0.5) {
        noStroke();
        fill(100, 200, 255, alpha * 0.5);
        ellipse(p.x + splashOffsetX * w,
                p.y + splashOffsetY * w,
                splashSize * w * 0.8,
                splashSize * w * 0.8);
      }

      // 接近終點的水霧擴散
      if (lifespan < 80) {
        noStroke();
        float mistAlpha = map(lifespan, 80, 0, 0, alpha * 0.4);
        float mistSize  = map(lifespan, 80, 0, w, w * 4);
        fill(150, 210, 255, mistAlpha);
        ellipse(p.x + mistOffsetX, p.y + mistOffsetY, mistSize, mistSize);
      }

    } else if (currentAgent == Agent.POWDER) {
      blendMode(SCREEN);
      noStroke();
      float sz = map(lifespan, 255, 0, initialSize, initialSize * 5);

      // 外層粉塵雲
      fill(c, alpha * 0.4);
      ellipse(p.x, p.y,
              sz + splashOffsetX * 2,
              sz + splashOffsetY * 2);

      // 核心顆粒
      fill(c, alpha * 0.8);
      ellipse(p.x + splashOffsetX * 1.5,
              p.y + splashOffsetY * 1.5,
              sz * 0.4, sz * 0.4);
      blendMode(BLEND);

    } else if (currentAgent == Agent.CO2) {
      blendMode(SCREEN);
      noStroke();
      float sz = map(lifespan, 255, 0, 10, 60);

      // 主體霧氣
      fill(255, alpha * 0.6);
      ellipse(p.x, p.y, sz, sz);

      // 冰晶細節（固定位置，不閃爍）
      if (splashSize > 0.6) {
        fill(200, 230, 255, alpha);
        rect(p.x + splashOffsetX * 3,
             p.y + splashOffsetY * 3, 2, 2);
      }
      blendMode(BLEND);

    } else {
      noStroke();
      fill(c, alpha);
      ellipse(p.x, p.y, 8, 8);
    }

    popStyle();
  }

  void checkFireCollision() {
    float hitDist = dist(p.x, p.y, firePos.x, firePos.y);

    float effectiveRadius;
    if (currentAgent == Agent.POWDER) {
      effectiveRadius = 80;
    } else if (currentAgent == Agent.CO2) {
      effectiveRadius = 60;
    } else {
      effectiveRadius = 50;
    }

    if (hitDist < effectiveRadius) {
      float normalized = hitDist / effectiveRadius;
      float distFactor = constrain(1.0 - (normalized * normalized), 0, 1);
      applyExtinguishLogic(distFactor);
      hasCollided = true;
    }
  }

  void applyExtinguishLogic(float distFactor) {
    float heightPenalty;
    if (p.y < firePos.y - 20) {
      heightPenalty = 0.15;
    } else if (p.y < firePos.y + 10) {
      heightPenalty = 1.0;
    } else {
      heightPenalty = 0.5;
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
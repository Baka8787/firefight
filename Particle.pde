/**
 * Particle.pde (CO2 氣體體積與消散強化版)
 * 解決 CO2 噴灑過細問題，模擬從高壓噴流轉化為濃密冷霧的動態
 */
class Particle {
  PVector p, v, prevP; 
  float lifespan, lifespanDecay;
  color c;
  float initialSize;
  float driftSeed; 

  // 生命緩衝區：設為 2.0 確保粒子在到達準心 (127) 後，仍有 50% 的生命展現氣化效果 [cite: 124]
  float lifeBuffer = 2.0; 

  float splashOffsetX, splashOffsetY, splashSize;
  float mistOffsetX, mistOffsetY;

  static final color WATER_DEEP  = #3C96FF; 
  static final color WATER_MIST  = #C8E6FF; 

  Particle(PVector p, PVector v, color c) {
    this.p      = p.copy();
    this.prevP  = p.copy();
    this.v      = v.copy();
    this.c      = c;
    this.driftSeed   = random(1000);

    // 1. 生命衰減隨機化：消除尾端平整硬切感的關鍵 [cite: 38]
    float decayVar = random(0.85, 1.15);

    if (currentAgent == Agent.POWDER) {
      this.initialSize = random(8, 12);
      this.lifespanDecay = (255.0 / (35.0 * lifeBuffer)) * decayVar; 
    } else if (currentAgent == Agent.CO2) {
      // CO2 初始噴流寬度稍微加粗，增加存在感
      this.initialSize = 15; 
      this.lifespanDecay = (255.0 / (26.0 * lifeBuffer)) * decayVar;
    } else {
      this.initialSize = random(6, 14);
      this.lifespanDecay = (255.0 / (38.0 * lifeBuffer)) * decayVar;
    }

    this.lifespan = 255;

    // 預計算美術偏移
    this.splashOffsetX = random(-1.5, 1.5);
    this.splashOffsetY = random(-1.0, 1.0);
    this.splashSize    = random(0.3, 0.9);
    this.mistOffsetX   = random(-12, 12); // CO2 氣體亂流較強
    this.mistOffsetY   = random(-12, 12);
  }

  void update() {
    prevP.set(p);

    if (currentAgent == Agent.WATER) {
      v.y += 0.28; v.mult(0.985);
    } else if (currentAgent == Agent.POWDER) {
      v.y += 0.03; v.mult(0.965); 
      float noiseX = (noise(driftSeed, frameCount * 0.04) - 0.5) * 0.9;
      v.x += noiseX;   
    } else if (currentAgent == Agent.CO2) {
      // CO2 物理：極速噴射後迅速受到空氣阻力慢下來，並產生上浮感 [cite: 122-123]
      v.mult(0.92); // 阻力加大，讓氣體在準心處迅速擴張
      v.y -= 0.03;  // 模擬熱氣流帶著二氧化碳微幅上升
    }

    // 末端動能衰減：產生自然的消散弧度
    if (lifespan < 80) {
      v.mult(0.94);
    }

    p.add(v);
    lifespan -= lifespanDecay;
  }

  void display() {
    float lifeRatio = lifespan / 255.0; 
    float alphaFactor = pow(lifeRatio, 1.6); // 讓消失更柔和
    float alpha = map(alphaFactor, 1, 0, 190, 0);

    pushStyle();
    noStroke();

    // --- 分支：二氧化碳 (CO2) 專項渲染 ---
    if (currentAgent == Agent.CO2) {
      // 1. 高壓噴流核心 (High-Pressure Jet)
      // 使用 line 繪製運動模糊，但給予漸層寬度
      float jetW = map(lifeRatio, 1, 0, initialSize, 2);
      stroke(255, alpha * 0.85); // 核心為實白色
      strokeWeight(jetW);
      line(p.x, p.y, prevP.x, prevP.y); 

      // 2. 氣化冷霧雲團 (Expanding Cold Fog)
      // 門檻設在抵達準心前 (130)，確保穿過準心時已經擴大為氣團
      if (lifespan < 130) {
        noStroke();
        blendMode(SCREEN); // 使用發光疊加模擬氣體質感
        
        float fogAlpha = map(alphaFactor, 0.51, 0, 0, alpha * 0.6);
        // CO2 的特點是膨脹倍率極大 (初段噴流的 15 倍以上)
        float fogSize  = map(lifeRatio, 0.51, 0, jetW, 100); 
        
        fill(220, 240, 255, fogAlpha); // 帶一點極低溫的淡藍色
        // 多層疊加打破硬邊界
        ellipse(p.x + mistOffsetX, p.y + mistOffsetY, fogSize, fogSize * 0.85);
        fill(255, fogAlpha * 0.4); 
        ellipse(p.x - mistOffsetX * 0.5, p.y - mistOffsetY * 0.5, fogSize * 0.7, fogSize * 0.6);
        
        // 加入乾冰昇華產生的細微冰晶閃爍
        if (splashSize > 0.8) {
          fill(255, alpha);
          rect(p.x + splashOffsetX * 5, p.y + splashOffsetY * 5, 2, 2);
        }
        blendMode(BLEND);
      }

    // --- 分支：水粒子 ---
    } else if (currentAgent == Agent.WATER) {
      float w = map(lifeRatio, 1, 0, initialSize * 0.5, initialSize * 2.0);
      color waterCol = lerpColor(WATER_DEEP, WATER_MIST, 1.0 - lifeRatio);
      stroke(waterCol, alpha);
      strokeWeight(w);
      line(p.x, p.y, prevP.x, prevP.y); 

      if (lifespan < 125) {
        float mAlpha = map(alphaFactor, 0.49, 0, 0, alpha * 0.7);
        float mSize  = map(lifeRatio, 0.49, 0, w, w * 5.5);
        fill(150, 210, 255, mAlpha);
        ellipse(p.x + mistOffsetX, p.y + mistOffsetY, mSize, mSize);
      }

    // --- 分支：乾粉 (ABC Powder) ---
    } else if (currentAgent == Agent.POWDER) {
      float coreW = map(lifeRatio, 1, 0, initialSize, initialSize * 0.3);
      stroke(c, alpha * 0.9);
      strokeWeight(coreW);
      line(p.x, p.y, prevP.x, prevP.y); 

      if (lifespan < 135) {
        blendMode(SCREEN); 
        float cloudAlpha = map(alphaFactor, 0.53, 0, 0, alpha * 0.5);
        float cloudSize  = map(lifeRatio, 0.53, 0, coreW * 2, coreW * 15); 
        fill(c, cloudAlpha);
        ellipse(p.x + mistOffsetX, p.y + mistOffsetY, cloudSize, cloudSize * 0.9);
        blendMode(BLEND);
      }
    }

    popStyle();
  }

  boolean isDead() { 
    return lifespan <= 0 || p.y > height + 120; 
  } 
}
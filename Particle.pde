/**
 * Particle.pde
 * 負責滅火介質（水、乾粉、CO2）的物理模擬 (Physics Simulation) 與視覺呈現
 */
class Particle {
  PVector p, v, prevP; 
  float lifespan;
  float lifespanDecay;
  color c;
  float initialSize;
  float driftSeed; 
  boolean hasCollided = false;

  // 視覺偏移變數：用於控制霧化時機
  // 透過延長總壽命，讓水柱看起來會「穿過」準心後才完全消散
  float lifeBuffer = 1.4; 

  float splashOffsetX, splashOffsetY, splashSize;
  float mistOffsetX, mistOffsetY;

  // 靜態顏色基底 (Static Color Constants)，優化渲染效能，避免每幀計算
  static final color WATER_DEEP  = #3C96FF;  // 深藍水柱
  static final color WATER_MIST  = #C8E6FF;  // 淡白水霧

  Particle(PVector p, PVector v, color c) {
    this.p      = p.copy();
    this.prevP  = p.copy();
    this.v      = v.copy();
    this.c      = c;
    this.driftSeed   = random(1000);
    this.hasCollided = false;

    // 1. 根據藥劑類型設定初始尺寸 (Initial Size) [cite: 116]
    if      (currentAgent == Agent.POWDER) this.initialSize = random(5, 8);
    else if (currentAgent == Agent.CO2)    this.initialSize = 12;
    else                                   this.initialSize = random(6, 14);

    // 2. 設定動態生命衰減速率 (Lifespan Decay) 
    // 加入 lifeBuffer 因子，讓實際壽命大於飛行到準心的時間 (flightFrames)
    if (currentAgent == Agent.WATER) {
      this.lifespanDecay = 255.0 / (38.0 * lifeBuffer); // 增加 40% 飛行距離 [cite: 126]
    } else if (currentAgent == Agent.POWDER) {
      this.lifespanDecay = 255.0 / (33.0 * 1.2); 
    } else {
      this.lifespanDecay = 255.0 / (26.0 * 1.1); // CO2 消失最快 [cite: 124]
    }

    this.lifespan = 255;

    // 預先計算隨機位移偏移量，避免在 display() 中呼叫 random() 以提升效能
    this.splashOffsetX = random(-1.2, 1.2);
    this.splashOffsetY = random(-0.8, 0.8);
    this.splashSize    = random(0.2, 0.8);
    this.mistOffsetX   = random(-6, 6);
    this.mistOffsetY   = random(-6, 6);
  }

  /**
   * 更新物理狀態：包含重力 (Gravity)、阻力 (Drag) 與位置更新
   */
  void update() {
    prevP.set(p);

    if (currentAgent == Agent.WATER) {
      v.y += 0.28;     // 水的重力感 [cite: 117]
      v.mult(0.985);   // 水的空氣阻力 [cite: 118]
    } else if (currentAgent == Agent.POWDER) {
      v.y += 0.04;     
      v.mult(0.96);    // 粉末阻力較大 [cite: 118]
      // 模擬粉塵在空氣中的布朗運動 (Brownian Motion) [cite: 120]
      float noiseX = (noise(driftSeed, frameCount * 0.05) - 0.5) * 0.5;
      v.x += noiseX;   
    } else if (currentAgent == Agent.CO2) {
      v.y += 0.02;     // 氣體微幅下墜（模擬高壓噴射後的冷空氣沉降） [cite: 123]
      v.mult(0.94);    // 氣體快速減速 [cite: 122]
    }

    p.add(v);
    lifespan -= lifespanDecay;
  }

  /**
   * 視覺繪製：根據藥劑類型切換渲染模式 (Water / Powder / CO2)
   */
  void display() {
    float alpha     = map(lifespan, 255, 0, 180, 0);
    float lifeRatio = lifespan / 255.0; 

    pushStyle();
    noStroke();

    if (currentAgent == Agent.WATER) {
      // 1. 主水柱：寬度隨生命週期增加 (噴灑散開) [cite: 128]
      float w = map(lifeRatio, 1, 0, initialSize * 0.5, initialSize * 1.8);
      
      // 顏色由深藍過渡到淺白水霧 (Color Transition)
      color waterCol = lerpColor(WATER_DEEP, WATER_MIST, 1.0 - lifeRatio);
      stroke(waterCol, alpha);
      strokeWeight(w);
      line(p.x, p.y, prevP.x, prevP.y); // 動態模糊效果 (Motion Blur) [cite: 129]

      // 2. 飛濺水花 (Water Spatters)
      if (splashSize > 0.5) {
        noStroke();
        fill(100, 200, 255, alpha * 0.5);
        ellipse(p.x + splashOffsetX * w, p.y + splashOffsetY * w, splashSize * w, splashSize * w);
      }

      // 3. 延後觸發的水霧 (Delayed Mist)：當壽命低於門檻時才出現
      // 由於總壽命延長，這會讓水霧出現在準心之後
      float mistThreshold = 110; 
      if (lifespan < mistThreshold) {
        noStroke();
        // alpha 在穿過準心後平滑消失
        float mistAlpha = map(lifespan, mistThreshold, 0, 0, alpha * 0.55);
        float mistSize  = map(lifespan, mistThreshold, 0, w, w * 6);
        fill(150, 210, 255, mistAlpha);
        ellipse(p.x + mistOffsetX, p.y + mistOffsetY, mistSize, mistSize);
      }

    } else if (currentAgent == Agent.POWDER) {
      // 乾粉渲染：使用 SCREEN 模式增加發光感 [cite: 130-134]
      float sz = map(lifeRatio, 1, 0, initialSize, initialSize * 5.5); 
      blendMode(SCREEN);
      fill(c, alpha * 0.4); 
      ellipse(p.x, p.y, sz + splashOffsetX * 2, sz + splashOffsetY * 2); 
      fill(c, alpha * 0.8); 
      ellipse(p.x + splashOffsetX, p.y + splashOffsetY, sz * 0.3, sz * 0.3); 
      blendMode(BLEND);

    } else if (currentAgent == Agent.CO2) {
      // CO2 渲染：模擬低溫白霧效果 [cite: 135-138]
      float sz = map(lifeRatio, 1, 0, 10, 65);
      blendMode(SCREEN);
      fill(255, alpha * 0.6); 
      ellipse(p.x, p.y, sz, sz); 
      // 隨機冰晶亮點
      if (splashSize > 0.6) {
        fill(200, 230, 255, alpha);
        rect(p.x + splashOffsetX * 3, p.y + splashOffsetY * 3, 2, 2); 
      }
      blendMode(BLEND);

    } else {
      fill(c, alpha);
      ellipse(p.x, p.y, 8, 8);
    }

    popStyle();
  }

  /**
   * 判定粒子是否已死亡 (OutOfLife)
   */
  boolean isDead() { 
    return lifespan <= 0 || p.y > height + 50; 
  } 
}
/**
 * Particle.pde
 * 負責滅火介質（水、乾粉、CO2）的物理模擬與視覺呈現。
 * 優化重點：生命緩衝區、尾端隨機化、以及氣化體積感。
 */
class Particle {
  PVector p, v, prevP; 
  float lifespan, lifespanDecay;
  color c;
  float initialSize;
  float driftSeed; 

  // 生命緩衝區：數值越大，噴灑越會「穿過」準心後才消失。
  // 設為 2.2 確保粒子抵達準心 (127) 時，仍保有 50% 以上的生命進行擴散。 [cite: 124]
  float lifeBuffer = 2.2; 

  float splashOffsetX, splashOffsetY, splashSize;
  float mistOffsetX, mistOffsetY;

  // 靜態顏色基底，優化渲染效能
  static final color WATER_DEEP  = #3C96FF; 
  static final color WATER_MIST  = #C8E6FF; 

  Particle(PVector p, PVector v, color c) {
    this.p      = p.copy();
    this.prevP  = p.copy();
    this.v      = v.copy();
    this.c      = c;
    this.driftSeed   = random(1000);

    // 1. 生命衰減隨機化：消除尾端平整硬切感的關鍵因子。 [cite: 38]
    float decayVar = random(0.85, 1.15);

    // 2. 根據藥劑類型設定尺寸與衰減速率（需與 generateParticles 幀數對齊）。 [cite: 116, 124-126]
    if (currentAgent == Agent.POWDER) {
      this.initialSize = random(8, 12);
      this.lifespanDecay = (255.0 / (35.0 * lifeBuffer)) * decayVar; 
    } else if (currentAgent == Agent.CO2) {
      this.initialSize = 18;
      this.lifespanDecay = (255.0 / (20.0 * lifeBuffer)) * decayVar;
    // ---> 新增：METAL 粒子的尺寸與衰減 <---
    } else if (currentAgent == Agent.METAL) {
      this.initialSize = random(10, 15);
      this.lifespanDecay = (255.0 / (32.0 * lifeBuffer)) * decayVar;
    } else {
      this.initialSize = random(6, 14);
      this.lifespanDecay = (255.0 / (38.0 * lifeBuffer)) * decayVar;
    }

    this.lifespan = 255;

    // 預計算隨機偏移，避免在 display() 中呼叫 random()。
    this.splashOffsetX = random(-1.5, 1.5);
    this.splashOffsetY = random(-1.0, 1.0);
    this.splashSize    = random(0.3, 0.9);
    this.mistOffsetX   = random(-12, 12); 
    this.mistOffsetY   = random(-12, 12);
  }

  /**
   * 更新物理狀態。 [cite: 117-123]
   */
void update() {
    prevP.set(p);

    if (currentAgent == Agent.WATER) {
      v.y += 0.28; 
      v.mult(0.985);
      
    // ---> 關鍵修改：把 METAL 加進來，並根據藥劑給予不同重力 <---
    } else if (currentAgent == Agent.POWDER || currentAgent == Agent.METAL) {
      // 金屬粉末比較重 (0.05)，一般乾粉較輕 (0.03)
      v.y += (currentAgent == Agent.METAL) ? 0.05 : 0.03; 
      v.mult(0.965); 
      // 模擬粉塵在空氣中的晃動
      v.x += (noise(driftSeed, frameCount * 0.05) - 0.5) * 0.9;
      
    } else if (currentAgent == Agent.CO2) {
      v.mult(0.96); // 降低阻力，讓氣體噴射感更扎實
      v.y -= 0.02;  // 氣體受熱輕微上浮
    }

    // 末端動能衰減：產生自然的下墜弧度
    if (lifespan < 80) {
      v.mult(0.94);
      if (currentAgent != Agent.CO2) v.y += 0.1; 
    }

    p.add(v);
    lifespan -= lifespanDecay;
  }

  /**
   * 視覺繪製。 
   */
  void display() {
    float lifeRatio = lifespan / 255.0; 
    // 非線性透明度映射，讓消失過程更柔和
    float alphaFactor = pow(lifeRatio, 1.1); 
    float alpha = map(alphaFactor, 1, 0, 255, 0);

    pushStyle();
    noStroke();

    if (currentAgent == Agent.WATER) {
      float sensorVal = getFilteredSensorData(); // 取得即時感測器數值 (0-1023) [cite: 174, 196]
      
      // streamFactor: 0 為全水霧，1 為純水柱
      float streamFactor = map(sensorVal, 0, 1023, 0.0, 1.0); 

      // 1. 水柱核心 (Line) - 當 streamFactor 靠近 1 時，線條要更粗、更明顯
      float w = map(lifeRatio, 1, 0, initialSize * (0.5 + 2.0 * streamFactor), initialSize * (1.0)); 
      color waterCol = lerpColor(WATER_DEEP, WATER_MIST, 1.0 - lifeRatio); 
      
      stroke(waterCol, alpha);
      strokeWeight(w);
      line(p.x, p.y, prevP.x, prevP.y); 

      // 2. 水霧部分 (Ellipse) - 當 streamFactor 靠近 0 時，擴散圓圈要變大且透明
      if (lifespan < 180) { // 提早開始渲染水霧效果
        noStroke();
        // 當 streamFactor 越小，水霧透明度越高、尺寸越大
        float mAlpha = map(alphaFactor, 0.5, 0, 0, alpha * (1.0 - streamFactor)); 
        float mSize = map(lifeRatio, 0.5, 0, w, w * (8.0 - 7.0 * streamFactor));
        
        fill(150, 210, 255, mAlpha);
        ellipse(p.x + mistOffsetX, p.y + mistOffsetY, mSize, mSize); 
      }
    } else if (currentAgent == Agent.POWDER || currentAgent == Agent.METAL) {
      // 乾粉核心
      float coreW = map(lifeRatio, 1, 0, initialSize, initialSize * 0.3);
      stroke(c, alpha * 0.9);
      strokeWeight(coreW);
      line(p.x, p.y, prevP.x, prevP.y); 

      // 乾粉/金屬粉雲團 (使用 SCREEN 混合模式增加亮度)
      if (lifespan < 135) {
        noStroke();
        blendMode(SCREEN); // 加亮混合模式，增強視覺衝擊
        
        float cloudAlpha = map(alphaFactor, 0.53, 0, 0, alpha * 0.6); // 提升雲團透明度
        float cloudSize  = map(lifeRatio, 0.53, 0, coreW * 2, coreW * 15); 
        fill(c, cloudAlpha);
        ellipse(p.x + mistOffsetX, p.y + mistOffsetY, cloudSize, cloudSize * 0.9);
        
        blendMode(BLEND); // 恢復預設混合模式
      }

    } else if (currentAgent == Agent.CO2) {
      // CO2 高壓噴流
      float jetW = map(lifeRatio, 1, 0, initialSize, 2);
      stroke(255, alpha * 0.85);
      strokeWeight(jetW);
      line(p.x, p.y, prevP.x, prevP.y); 

      // CO2 低溫冷霧 (穿過準心後劇烈膨脹)。 
      if (lifespan < 160) {
        noStroke();
        float fogAlpha = map(alphaFactor, 0.62, 0, 0, alpha * 0.6);
        float fogSize  = map(lifeRatio, 0.62, 0, jetW, 100); 
        fill(255, fogAlpha);
        ellipse(p.x + mistOffsetX * 0.5, p.y + mistOffsetY * 0.5, fogSize, fogSize * 0.8);
      }
    }

    popStyle();
  }

  boolean isDead() { 
    return lifespan <= 0 || p.y > height + 100; 
  } 
}

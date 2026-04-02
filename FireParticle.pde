class FireParticle {
  PVector p, v;
  float lifespan, maxLife;
  float uniqueSeed;
  float jitterX, jitterY;   // 位置抖動（每兩幀更新）
  float sizeJitter;         // 尺寸抖動（語意獨立）
  float noiseForceCached;

  // 固定 RGB 基底，alpha 在 display() 動態合成，避免每幀 new color
  static final color BASE_WHITE  = #FFE696;  // 黃白（根部高溫）
  static final color BASE_ORANGE = #FF7814;  // 橘（中段）
  static final color BASE_RED    = #BE1E0A;  // 深紅（衰退）
  static final color BASE_SMOKE  = #6E6E6E;  // 煙灰（消亡）

  FireParticle(PVector basePos) {
    this.p = new PVector(basePos.x + random(-20, 20), basePos.y);
    this.v = new PVector(random(-1.0, 1.0), random(-5.8, -3.0));
    this.maxLife = random(70, 110);
    this.lifespan = maxLife;
    this.uniqueSeed = random(10000);
    this.jitterX = 0;
    this.jitterY = 0;
    this.sizeJitter = random(1.5, 3.5);  // 初始化一次，避免頻繁 random
    this.noiseForceCached = 0;
  }

  void update() {
    float hRatio = constrain(map(p.y, height * 0.9, height * 0.4, 0.2, 2.2), 0.2, 2.2);

    // noise 與抖動每兩幀更新一次，用 uniqueSeed 錯開相位，避免全部粒子同步閃爍
    if ((frameCount + int(uniqueSeed)) % 2 == 0) {
      float n = noise(p.x * 0.012, p.y * 0.012, frameCount * 0.018 + uniqueSeed);
      noiseForceCached = map(n, 0, 1, -1.1, 1.1) * hRatio;
      jitterX = random(-1.2, 1.2);
      jitterY = random(-1.2, 1.2);
    }
    v.x += noiseForceCached;

    // 非線性收束：平方項讓遠端拉力更強、近端更柔
    float dx = firePos.x - p.x;
    float centerPull = constrain(0.0008 * dx * abs(dx) * 0.001, -0.9, 0.9);
    v.x += centerPull;

    v.y -= 0.13;
    v.mult(0.965);

    p.add(v);
    lifespan -= map(hRatio, 0.2, 2.2, 1.7, 2.4);
  }

  void display() {
    float lifeRatio = lifespan / maxLife;
    float alpha     = map(lifeRatio, 0, 1, 0, 210);
    float w         = map(lifeRatio, 1, 0, 22, 5) + sizeJitter;
    float h         = map(lifeRatio, 1, 0, 36, 12) + sizeJitter;

    // 顏色分三段連續過渡（0→1 方向統一，閱讀更直覺）
    color outerColor;
    if (lifeRatio > 0.5) {
      outerColor = lerpColor(BASE_ORANGE, BASE_WHITE, map(lifeRatio, 0.5, 1.0, 0, 1));
    } else if (lifeRatio > 0.15) {
      outerColor = lerpColor(BASE_RED, BASE_ORANGE, map(lifeRatio, 0.15, 0.5, 0, 1));
    } else {
      outerColor = lerpColor(BASE_SMOKE, BASE_RED, map(lifeRatio, 0, 0.15, 0, 1));
    }

    // 核心閃爍強度隨生命衰減，快消亡時核心也跟著熄滅
    float flickerStrength = lifeRatio * (0.8 + 0.2 * sin((frameCount + uniqueSeed) * 0.06));
    float coreAlpha       = alpha * 0.75 * flickerStrength;

    float x = p.x + jitterX;
    float y = p.y + jitterY;

    pushStyle();
    noStroke();

    // 外層火焰
    fill(red(outerColor), green(outerColor), blue(outerColor), alpha);
    ellipse(x, y, w, h);

    // 核心高光（白芯，尺寸隨生命縮小）
    fill(255, 255, 215, coreAlpha);
    ellipse(x, y, w * 0.45 * lifeRatio, h * 0.45 * lifeRatio);

    popStyle();
  }

  boolean isDead() {
    return lifespan <= 0 || p.y < -50 || p.x < -80 || p.x > width + 80;
  }
}
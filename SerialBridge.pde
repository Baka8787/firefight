import processing.serial.*;

SerialBridge bridge;

class CalibrationData {
  int analogMin = 50, analogMax = 900;
  float sensitivity = 25.0;

  static final int CAL_POINT_COUNT = 9;

  PVector[] imuPoints = new PVector[CAL_POINT_COUNT];
  float[] screenXs = new float[CAL_POINT_COUNT];
  float[] screenYs = new float[CAL_POINT_COUNT];

  PVector centerVec = new PVector();

  float[] modelX = {0, 1, 0, 0};
  float[] modelY = {0, 0, 1, 0};

  boolean calibrated = false;
  int calibrationStep = -1;
  int calibrationStepStartedAt = 0;

  CalibrationData() {
    for (int i = 0; i < CAL_POINT_COUNT; i++) {
      imuPoints[i] = new PVector();
    }
  }
}

class SerialBridge {
  PApplet app;
  Serial port;
  boolean connected, ready;

  String[] portList = {};
  int portIndex;

  float extPitch, extRoll, extYaw;
  int extAnalog;

  float hosePitch, hoseRoll, hoseYaw;
  int hoseAnalog;

  boolean extEnabled = false;
  boolean hoseEnabled = false;

  int calibrationDevice = 0;

  int lastPacketMillis = 0;
  int lastExtMillis = 0;
  int lastHoseMillis = 0;

  CalibrationData extCal = new CalibrationData();
  CalibrationData hoseCal = new CalibrationData();

  SerialBridge(PApplet app) {
    this.app = app;
  }

  void refreshPorts() {
    portList = Serial.list();
    portIndex = min(portIndex, max(0, portList.length - 1));
  }

  boolean connect() {
    if (portIndex < 0 || portIndex >= portList.length) return false;
    disconnect();
    try {
      port = new Serial(app, portList[portIndex], 115200);
      connected = true;
      ready = false;
      lastPacketMillis = 0;
      lastExtMillis = 0;
      lastHoseMillis = 0;
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  void disconnect() {
    ready = false;
    connected = false;
    lastPacketMillis = 0;
    lastExtMillis = 0;
    lastHoseMillis = 0;
    if (port != null) {
      try { port.stop(); } catch (Exception e) {}
      port = null;
    }
  }

  void poll() {
    if (!connected || port == null) return;
    try {
      while (port.available() > 0) {
        String line = port.readStringUntil('\n');
        if (line == null) break;
        line = line.trim();
        if (line.length() == 0) continue;

        if (line.equals("ready")) {
          port.write("cfg:ok\n");
          port.write("interval:20\n");
          ready = true;
          syncEnabledState();
        } else if (ready) {
          parseLine(line);
        }
      }
    } catch (Exception e) {
      disconnect();
    }
  }

  void syncEnabledState() {
    sendCommand("ext:" + (extEnabled ? 1 : 0));
    sendCommand("hose:" + (hoseEnabled ? 1 : 0));
  }

  private void parseLine(String line) {
    String[] segments = split(line, '|');
    boolean gotPacket = false;

    for (String seg : segments) {
      int colon = seg.indexOf(':');
      if (colon < 0) continue;

      String id = seg.substring(0, colon);
      String[] vals = split(seg.substring(colon + 1), ',');
      if (vals == null) continue;

      if (vals.length >= 4) {
        float p = float(vals[0]);
        float r = float(vals[1]);
        float y = float(vals[2]);
        int a = int(float(vals[3]));

        if (Float.isNaN(p) || Float.isNaN(r) || Float.isNaN(y)) continue;

        if (id.equals("ext")) {
          extPitch = p;
          extRoll = r;
          extYaw = y;
          extAnalog = a;
          lastExtMillis = millis();
          gotPacket = true;
        } else if (id.equals("hose")) {
          hosePitch = p;
          hoseRoll = r;
          hoseYaw = y;
          hoseAnalog = a;
          lastHoseMillis = millis();
          gotPacket = true;
        }
      } else if (vals.length >= 3) {
        float p = float(vals[0]);
        float r = float(vals[1]);
        int a = int(float(vals[2]));

        if (Float.isNaN(p) || Float.isNaN(r)) continue;

        if (id.equals("ext")) {
          extPitch = p;
          extRoll = r;
          extYaw = 0;
          extAnalog = a;
          lastExtMillis = millis();
          gotPacket = true;
        } else if (id.equals("hose")) {
          hosePitch = p;
          hoseRoll = r;
          hoseYaw = 0;
          hoseAnalog = a;
          lastHoseMillis = millis();
          gotPacket = true;
        }
      }
    }

    if (gotPacket) lastPacketMillis = millis();
  }

  boolean hasFreshData() {
    return ready && millis() - lastPacketMillis < 500;
  }

  boolean extFresh() {
    return ready && millis() - lastExtMillis < 500;
  }

  boolean hoseFresh() {
    return ready && millis() - lastHoseMillis < 500;
  }

  int currentGameDevice() {
    return currentAgent == Agent.WATER ? 1 : 0;
  }

  boolean currentGameDeviceEnabled() {
    return currentGameDevice() == 0 ? extEnabled : hoseEnabled;
  }

  boolean currentGameDeviceFresh() {
    return currentGameDevice() == 0 ? extFresh() : hoseFresh();
  }

  boolean currentGameDeviceActive() {
    return currentGameDeviceEnabled() && currentGameDeviceFresh();
  }

  CalibrationData activeCal() {
    return calibrationDevice == 0 ? extCal : hoseCal;
  }

  CalibrationData gameCal() {
    return currentGameDevice() == 0 ? extCal : hoseCal;
  }

  String calibrationDeviceName() {
    return calibrationDevice == 0 ? "滅火器" : "消防瞄子";
  }

  String currentAimDeviceName() {
    return currentGameDeviceActive() ? (currentGameDevice() == 0 ? "滅火器" : "消防瞄子") : "滑鼠";
  }

  String currentControlSourceName() {
    return currentAimDeviceName();
  }

  float activePitch() {
    return calibrationDevice == 0 ? extPitch : hosePitch;
  }

  float activeRoll() {
    return calibrationDevice == 0 ? extRoll : hoseRoll;
  }

  float activeYaw() {
    return calibrationDevice == 0 ? extYaw : hoseYaw;
  }

  int activeAnalog() {
    return calibrationDevice == 0 ? extAnalog : hoseAnalog;
  }

  PVector activeImuVector() {
    return new PVector(activePitch(), activeRoll(), activeYaw());
  }

  PVector gameImuVector() {
    if (currentGameDevice() == 0) return new PVector(extPitch, extRoll, extYaw);
    return new PVector(hosePitch, hoseRoll, hoseYaw);
  }

  float normalizeFromRange(int raw, int low, int high) {
    if (low == high) return 0;
    return constrain(map(raw, low, high, 0, 1), 0, 1);
  }

  float extAnalogNormalized() {
    return normalizeFromRange(extAnalog, extCal.analogMin, extCal.analogMax);
  }

  float hoseAnalogNormalized() {
    return normalizeFromRange(hoseAnalog, hoseCal.analogMin, hoseCal.analogMax);
  }

  int gameAnalog() {
    return currentGameDevice() == 0 ? extAnalog : hoseAnalog;
  }

  float gameAnalogNormalized() {
    CalibrationData c = gameCal();
    return normalizeFromRange(gameAnalog(), c.analogMin, c.analogMax);
  }

  int gameAnalogMapped() {
    if (currentGameDeviceActive()) return int(gameAnalogNormalized() * 1023);
    return app.mousePressed ? 800 : 100;
  }

  boolean gamePressing() {
    if (currentGameDeviceActive()) return gameAnalogNormalized() > 0.01;
    return app.mousePressed;
  }

  String calibrationLowLabel() {
    return calibrationDevice == 0 ? "壓把・釋放點" : "放射型態・水霧端";
  }

  String calibrationHighLabel() {
    return calibrationDevice == 0 ? "壓把・最大點" : "放射型態・水柱端";
  }

  String calibrationLowHint() {
    return calibrationDevice == 0
      ? "[Enter] 壓把完全放開時記錄"
      : "[Enter] 將瞄子調到水霧端時記錄";
  }

  String calibrationHighHint() {
    return calibrationDevice == 0
      ? "[Enter] 壓把壓到底時記錄"
      : "[Enter] 將瞄子調到水柱端時記錄";
  }

  String enabledLabel(boolean enabled) {
    return enabled ? "啟用" : "停用";
  }

  boolean calibrating() {
    CalibrationData c = activeCal();
    return c.calibrationStep >= 0 && c.calibrationStep < CalibrationData.CAL_POINT_COUNT;
  }

  String calibrationStepLabel() {
    CalibrationData c = activeCal();
    switch (c.calibrationStep) {
      case 0: return "正中";
      case 1: return "上中";
      case 2: return "下中";
      case 3: return "左中";
      case 4: return "右中";
      case 5: return "左上";
      case 6: return "右上";
      case 7: return "左下";
      case 8: return "右下";
    }
    return "";
  }

  PVector calibrationGuidePoint() {
    float left = 100;
    float right = app.width - 100;
    float top = 90;
    float bottom = app.height - 90;
    float cx = app.width / 2.0;
    float cy = app.height / 2.0;

    switch (activeCal().calibrationStep) {
      case 0: return new PVector(cx, cy);
      case 1: return new PVector(cx, top);
      case 2: return new PVector(cx, bottom);
      case 3: return new PVector(left, cy);
      case 4: return new PVector(right, cy);
      case 5: return new PVector(left, top);
      case 6: return new PVector(right, top);
      case 7: return new PVector(left, bottom);
      case 8: return new PVector(right, bottom);
    }
    return new PVector(cx, cy);
  }

  void beginDirectionCalibration() {
    CalibrationData c = activeCal();
    c.calibrationStep = 0;
    c.calibrated = false;
    c.calibrationStepStartedAt = app.millis();
  }

  void cancelDirectionCalibration() {
    activeCal().calibrationStep = -1;
  }

  int calibrationStepDurationMillis() {
    CalibrationData c = activeCal();
    if (c.calibrationStep < 0) return 0;
    return c.calibrationStep == 0 ? 5000 : 3000;
  }

  int calibrationCountdownSeconds() {
    CalibrationData c = activeCal();
    if (c.calibrationStep < 0) return 0;
    int remain = calibrationStepDurationMillis() - (app.millis() - c.calibrationStepStartedAt);
    if (remain <= 0) return 0;
    return int(ceil(remain / 1000.0));
  }

  PVector captureStableVector() {
    int sampleCount = 18;
    PVector sum = new PVector();

    for (int i = 0; i < sampleCount; i++) {
      poll();
      sum.add(activePitch(), activeRoll(), activeYaw());
      app.delay(8);
    }

    sum.div((float)sampleCount);
    return sum;
  }

  void storeCalibrationSample(CalibrationData c, int index, PVector imu, PVector screenPoint) {
    c.imuPoints[index].set(imu);
    c.screenXs[index] = screenPoint.x;
    c.screenYs[index] = screenPoint.y;
  }

  boolean solve4x4(float[][] a, float[] b, float[] out) {
    float[][] m = new float[4][5];

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) m[r][c] = a[r][c];
      m[r][4] = b[r];
    }

    for (int col = 0; col < 4; col++) {
      int pivot = col;
      for (int r = col + 1; r < 4; r++) {
        if (abs(m[r][col]) > abs(m[pivot][col])) pivot = r;
      }

      if (abs(m[pivot][col]) < 0.000001) return false;

      if (pivot != col) {
        float[] tmp = m[pivot];
        m[pivot] = m[col];
        m[col] = tmp;
      }

      float div = m[col][col];
      for (int c = col; c < 5; c++) m[col][c] /= div;

      for (int r = 0; r < 4; r++) {
        if (r == col) continue;
        float factor = m[r][col];
        for (int c = col; c < 5; c++) m[r][c] -= factor * m[col][c];
      }
    }

    for (int i = 0; i < 4; i++) out[i] = m[i][4];
    return true;
  }

  boolean fitLinearModel(CalibrationData c) {
    c.centerVec.set(c.imuPoints[0]);

    float[][] ata = new float[4][4];
    float[] atbx = new float[4];
    float[] atby = new float[4];

    for (int i = 0; i < CalibrationData.CAL_POINT_COUNT; i++) {
      float dp = c.imuPoints[i].x - c.centerVec.x;
      float dr = c.imuPoints[i].y - c.centerVec.y;
      float dy = c.imuPoints[i].z - c.centerVec.z;
      float[] f = {1, dp, dr, dy};

      for (int r = 0; r < 4; r++) {
        for (int col = 0; col < 4; col++) {
          ata[r][col] += f[r] * f[col];
        }
        atbx[r] += f[r] * c.screenXs[i];
        atby[r] += f[r] * c.screenYs[i];
      }
    }

    float[] mx = new float[4];
    float[] my = new float[4];

    boolean okX = solve4x4(ata, atbx, mx);
    boolean okY = solve4x4(ata, atby, my);
    if (!okX || !okY) return false;

    for (int i = 0; i < 4; i++) {
      c.modelX[i] = mx[i];
      c.modelY[i] = my[i];
    }
    return true;
  }

  void captureDirectionCalibration() {
    CalibrationData c = activeCal();
    if (c.calibrationStep < 0) return;

    int step = c.calibrationStep;
    PVector imu = captureStableVector();
    PVector screenPoint = calibrationGuidePoint();
    storeCalibrationSample(c, step, imu, screenPoint);

    c.calibrationStep++;

    if (c.calibrationStep >= CalibrationData.CAL_POINT_COUNT) {
      c.calibrated = fitLinearModel(c);
      c.calibrationStep = -1;
    } else {
      c.calibrationStepStartedAt = app.millis();
    }
  }

  void updateDirectionCalibration() {
    CalibrationData c = activeCal();
    if (c.calibrationStep < 0) return;
    if (app.millis() - c.calibrationStepStartedAt >= calibrationStepDurationMillis()) {
      captureDirectionCalibration();
    }
  }

  float predictX(PVector imu, CalibrationData c) {
    float dp = imu.x - c.centerVec.x;
    float dr = imu.y - c.centerVec.y;
    float dy = imu.z - c.centerVec.z;
    return c.modelX[0] + c.modelX[1] * dp + c.modelX[2] * dr + c.modelX[3] * dy;
  }

  float predictY(PVector imu, CalibrationData c) {
    float dp = imu.x - c.centerVec.x;
    float dr = imu.y - c.centerVec.y;
    float dy = imu.z - c.centerVec.z;
    return c.modelY[0] + c.modelY[1] * dp + c.modelY[2] * dr + c.modelY[3] * dy;
  }

  float targetX() {
    if (!currentGameDeviceActive()) return app.mouseX;

    CalibrationData c = gameCal();
    PVector imu = gameImuVector();

    if (c.calibrated) {
      return constrain(predictX(imu, c), 0, app.width);
    }

    return constrain(app.width / 2.0 + imu.z * c.sensitivity, 0, app.width);
  }

  float targetY() {
    if (!currentGameDeviceActive()) return app.mouseY;

    CalibrationData c = gameCal();
    PVector imu = gameImuVector();

    if (c.calibrated) {
      return constrain(predictY(imu, c), 0, app.height);
    }

    return constrain(app.height / 2.0 + imu.x * c.sensitivity, 0, app.height);
  }

  float activeTargetX() {
    boolean fresh = calibrationDevice == 0 ? extFresh() : hoseFresh();
    if (!fresh) return app.mouseX;

    CalibrationData c = activeCal();
    PVector imu = activeImuVector();

    if (c.calibrated) return constrain(predictX(imu, c), 0, app.width);
    return constrain(app.width / 2.0 + imu.z * c.sensitivity, 0, app.width);
  }

  float activeTargetY() {
    boolean fresh = calibrationDevice == 0 ? extFresh() : hoseFresh();
    if (!fresh) return app.mouseY;

    CalibrationData c = activeCal();
    PVector imu = activeImuVector();

    if (c.calibrated) return constrain(predictY(imu, c), 0, app.height);
    return constrain(app.height / 2.0 + imu.x * c.sensitivity, 0, app.height);
  }

  void calibrateAnalogMin() {
    activeCal().analogMin = activeAnalog();
  }

  void calibrateAnalogMax() {
    activeCal().analogMax = activeAnalog();
  }

  void sendCommand(String cmd) {
    if (connected && port != null) {
      try { port.write(cmd + "\n"); } catch (Exception e) {}
    }
  }
}

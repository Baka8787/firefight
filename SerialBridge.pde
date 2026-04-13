import processing.serial.*;

SerialBridge bridge;

class CalibrationData {
  int analogMin = 50;
  int analogMax = 900;
  float sensitivity = 10.0;

  PVector centerVec = new PVector();
  PVector upVec = new PVector();
  PVector downVec = new PVector();
  PVector leftVec = new PVector();
  PVector rightVec = new PVector();

  PVector axisX = new PVector(1, 0, 0);
  PVector axisY = new PVector(0, 1, 0);

  float leftRange = 1;
  float rightRange = 1;
  float upRange = 1;
  float downRange = 1;

  boolean calibrated = false;
  int calibrationStep = -1;
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

  void parseLine(String line) {
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

  CalibrationData activeCal() {
    return calibrationDevice == 0 ? extCal : hoseCal;
  }

  CalibrationData gameCal() {
    return currentGameDevice() == 0 ? extCal : hoseCal;
  }

  int currentGameDevice() {
    return currentAgent == Agent.WATER ? 1 : 0;
  }

  String currentGameDeviceName() {
    return currentGameDevice() == 0 ? "滅火器" : "消防瞄子";
  }

  String currentControlSourceName() {
    return gameControlActive() ? currentGameDeviceName() : "滑鼠";
  }

  boolean gameControlActive() {
    if (currentGameDevice() == 0) return extEnabled && extFresh();
    return hoseEnabled && hoseFresh();
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

  float gamePitch() {
    return currentGameDevice() == 0 ? extPitch : hosePitch;
  }

  float gameRoll() {
    return currentGameDevice() == 0 ? extRoll : hoseRoll;
  }

  float gameYaw() {
    return currentGameDevice() == 0 ? extYaw : hoseYaw;
  }

  int gameAnalog() {
    return currentGameDevice() == 0 ? extAnalog : hoseAnalog;
  }

  float normalizeFromRange(int raw, int low, int high) {
    if (low == high) return 0;
    return constrain(map(raw, low, high, 0, 1), 0, 1);
  }

  float activeAnalogNormalized() {
    CalibrationData c = activeCal();
    return normalizeFromRange(activeAnalog(), c.analogMin, c.analogMax);
  }

  float extAnalogNormalized() {
    return normalizeFromRange(extAnalog, extCal.analogMin, extCal.analogMax);
  }

  float hoseAnalogNormalized() {
    return normalizeFromRange(hoseAnalog, hoseCal.analogMin, hoseCal.analogMax);
  }

  float gameAnalogNormalized() {
    CalibrationData c = gameCal();
    return normalizeFromRange(gameAnalog(), c.analogMin, c.analogMax);
  }

  int gameAnalogMapped() {
    if (gameControlActive()) return int(gameAnalogNormalized() * 1023);
    return app.mousePressed ? 800 : 100;
  }

  boolean gamePressing() {
    if (gameControlActive()) return gameAnalogNormalized() > 0.01;
    return app.mousePressed;
  }

  String calibrationDeviceName() {
    return calibrationDevice == 0 ? "滅火器" : "消防瞄子";
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

  float mapWithCenter(float value, float low, float mid, float high, float outLow, float outMid, float outHigh) {
    if (value <= mid) {
      if (abs(mid - low) < 0.0001) return outMid;
      return map(value, low, mid, outLow, outMid);
    }
    if (abs(high - mid) < 0.0001) return outMid;
    return map(value, mid, high, outMid, outHigh);
  }

  float projectX(PVector v, CalibrationData c) {
    return PVector.sub(v, c.centerVec).dot(c.axisX);
  }

  float projectY(PVector v, CalibrationData c) {
    return PVector.sub(v, c.centerVec).dot(c.axisY);
  }

  float mapTargetX(PVector v, CalibrationData c) {
    if (c.calibrated) {
      return constrain(
        mapWithCenter(projectX(v, c), -c.leftRange, 0, c.rightRange, 0, app.width * 0.5, app.width),
        0, app.width
      );
    }
    return constrain(app.width / 2.0 + v.z * c.sensitivity, 0, app.width);
  }

  float mapTargetY(PVector v, CalibrationData c) {
    if (c.calibrated) {
      return constrain(
        mapWithCenter(projectY(v, c), -c.upRange, 0, c.downRange, 0, app.height * 0.5, app.height),
        0, app.height
      );
    }
    return constrain(app.height / 2.0 + v.x * c.sensitivity, 0, app.height);
  }

  float targetX() {
    if (!gameControlActive()) return app.mouseX;
    return mapTargetX(new PVector(gamePitch(), gameRoll(), gameYaw()), gameCal());
  }

  float targetY() {
    if (!gameControlActive()) return app.mouseY;
    return mapTargetY(new PVector(gamePitch(), gameRoll(), gameYaw()), gameCal());
  }

  float activeTargetX() {
    if (calibrationDevice == 0 && !extFresh()) return app.mouseX;
    if (calibrationDevice == 1 && !hoseFresh()) return app.mouseX;
    return mapTargetX(new PVector(activePitch(), activeRoll(), activeYaw()), activeCal());
  }

  float activeTargetY() {
    if (calibrationDevice == 0 && !extFresh()) return app.mouseY;
    if (calibrationDevice == 1 && !hoseFresh()) return app.mouseY;
    return mapTargetY(new PVector(activePitch(), activeRoll(), activeYaw()), activeCal());
  }

  boolean calibrating() {
    CalibrationData c = activeCal();
    return c.calibrationStep >= 0 && c.calibrationStep < 5;
  }

  String calibrationStepLabel() {
    CalibrationData c = activeCal();
    switch (c.calibrationStep) {
      case 0: return "正中";
      case 1: return "上";
      case 2: return "下";
      case 3: return "左";
      case 4: return "右";
    }
    return "";
  }

  PVector calibrationGuidePoint() {
    CalibrationData c = activeCal();
    switch (c.calibrationStep) {
      case 0: return new PVector(app.width / 2.0, app.height / 2.0);
      case 1: return new PVector(app.width / 2.0, 70);
      case 2: return new PVector(app.width / 2.0, app.height - 70);
      case 3: return new PVector(70, app.height / 2.0);
      case 4: return new PVector(app.width - 70, app.height / 2.0);
    }
    return new PVector(app.width / 2.0, app.height / 2.0);
  }

  void beginDirectionCalibration() {
    CalibrationData c = activeCal();
    c.calibrationStep = 0;
    c.calibrated = false;
  }

  void rebuildAxes(CalibrationData c) {
    PVector rightDelta = PVector.sub(c.rightVec, c.centerVec);
    PVector leftDelta = PVector.sub(c.leftVec, c.centerVec);
    PVector downDelta = PVector.sub(c.downVec, c.centerVec);
    PVector upDelta = PVector.sub(c.upVec, c.centerVec);

    PVector axisX = PVector.sub(rightDelta, leftDelta);
    if (axisX.magSq() < 0.0001) axisX = rightDelta.copy();
    if (axisX.magSq() < 0.0001) axisX = new PVector(1, 0, 0);
    axisX.normalize();

    PVector axisY = PVector.sub(downDelta, upDelta);
    if (axisY.magSq() < 0.0001) axisY = downDelta.copy();
    if (axisY.magSq() < 0.0001) axisY = new PVector(0, 1, 0);

    float mix = axisY.dot(axisX);
    axisY.sub(PVector.mult(axisX, mix));
    if (axisY.magSq() < 0.0001) axisY = new PVector(0, 1, 0);
    axisY.normalize();

    c.axisX.set(axisX);
    c.axisY.set(axisY);

    c.leftRange = max(0.0001, abs(leftDelta.dot(c.axisX)));
    c.rightRange = max(0.0001, abs(rightDelta.dot(c.axisX)));
    c.upRange = max(0.0001, abs(upDelta.dot(c.axisY)));
    c.downRange = max(0.0001, abs(downDelta.dot(c.axisY)));
  }

  void captureDirectionCalibration() {
    CalibrationData c = activeCal();
    if (c.calibrationStep < 0) return;

    PVector v = new PVector(activePitch(), activeRoll(), activeYaw());

    switch (c.calibrationStep) {
      case 0:
        c.centerVec.set(v);
        break;
      case 1:
        c.upVec.set(v);
        break;
      case 2:
        c.downVec.set(v);
        break;
      case 3:
        c.leftVec.set(v);
        break;
      case 4:
        c.rightVec.set(v);
        break;
    }

    c.calibrationStep++;

    if (c.calibrationStep >= 5) {
      c.calibrationStep = -1;
      rebuildAxes(c);
      c.calibrated = true;
    }
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
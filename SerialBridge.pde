import processing.serial.*;

SerialBridge bridge;

class CalibrationData {
  int analogMin = 50, analogMax = 900;
}

class SerialBridge {
  PApplet app;
  Serial port;
  boolean connected, ready;

  String[] portList = {};
  int portIndex;

  int extAnalog;
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
      if (vals == null || vals.length < 1) continue;

      int a = int(float(vals[0]));

      if (id.equals("ext")) {
        extAnalog = a;
        lastExtMillis = millis();
        gotPacket = true;
      } else if (id.equals("hose")) {
        hoseAnalog = a;
        lastHoseMillis = millis();
        gotPacket = true;
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

  int activeAnalog() {
    return calibrationDevice == 0 ? extAnalog : hoseAnalog;
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

  float targetX() {
    return app.mouseX;
  }

  float targetY() {
    return app.mouseY;
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

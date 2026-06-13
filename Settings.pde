int settingsIdx = 0;

void drawSettingsScreen() {
  if (bridge != null) bridge.poll();

  pushStyle();
  fill(0, 0, 0, 230);
  rect(0, 0, width, height);

  textFont(mainFont);
  boolean live = bridge != null && bridge.ready;
  boolean fresh = bridge != null && bridge.hasFreshData();

  fill(255);
  textAlign(CENTER, TOP);
  textSize(32);
  text("硬 體 設 定", width/2, 40);

  color dotColor = fresh ? color(0, 255, 100)
    : (bridge != null && bridge.connected) ? color(255, 200, 0)
    : color(255, 80, 80);
  noStroke();
  fill(dotColor);
  ellipse(width/2, 88, 10, 10);

  fill(200);
  textSize(14);
  String statusMsg = fresh ? "已連線 - 即時資料更新中"
    : live ? "已連線 - 等待資料..."
    : (bridge != null && bridge.connected) ? "等待 Arduino 握手..."
    : "未連線";
  text(statusMsg, width/2, 98);

  CalibrationData cal = (bridge != null) ? bridge.activeCal() : new CalibrationData();

  String portStr = "(無可用埠)";
  if (bridge != null && bridge.portList.length > 0)
    portStr = bridge.portList[bridge.portIndex];

  String calibrationLabel = (bridge != null) ? bridge.calibrationDeviceName() : "滅火器";
  boolean controlEnabled = false;
  if (bridge != null) {
    controlEnabled = (bridge.calibrationDevice == 0) ? bridge.extEnabled : bridge.hoseEnabled;
  }

  String controlLabel = (bridge != null) ? bridge.enabledLabel(controlEnabled) : "停用";

  String lowLabel = (bridge != null) ? bridge.calibrationLowLabel() : "壓把・釋放點";
  String highLabel = (bridge != null) ? bridge.calibrationHighLabel() : "壓把・最大點";
  String lowHint = (bridge != null) ? bridge.calibrationLowHint() : "";
  String highHint = (bridge != null) ? bridge.calibrationHighHint() : "";

  String[] labels = {
    "序列埠",
    "校準裝置",
    "控制狀態",
    lowLabel,
    highLabel
  };

  String[] values = {
    portStr,
    calibrationLabel,
    controlLabel,
    "已記錄 " + cal.analogMin,
    "已記錄 " + cal.analogMax
  };

  String[] hints = {
    (bridge != null && bridge.connected) ? "[Enter] 斷開" : "[← →] 選埠  [Enter] 連線",
    "[← →] 切換",
    "[← →] 切換 啟用 / 停用",
    live ? lowHint : "",
    live ? highHint : ""
  };

  float baseY = 128;
  float itemH = 50;
  float itemW = 560;
  float itemX = width / 2 - itemW / 2;

  textAlign(LEFT, TOP);
  for (int i = 0; i < labels.length; i++) {
    float y = baseY + i * itemH;

    if (i == settingsIdx) {
      fill(0, 150, 255, 80);
      stroke(0, 200, 255);
      strokeWeight(2);
    } else {
      fill(50, 180);
      noStroke();
    }
    rect(itemX, y, itemW, itemH - 5, 10);

    fill(255);
    textSize(17);
    text(labels[i], itemX + 16, y + 7);

    textAlign(RIGHT, TOP);
    fill(0, 255, 200);
    text(values[i], itemX + itemW - 16, y + 7);

    fill(120);
    textSize(11);
    text(hints[i], itemX + itemW - 16, y + 28);
    textAlign(LEFT, TOP);
  }

  if (bridge != null) {
    float panelY = baseY + labels.length * itemH + 8;
    float panelH = 150;

    fill(30, 220);
    noStroke();
    rect(itemX, panelY, itemW, panelH, 10);

    fill(255, 200, 0);
    textSize(14);
    text("即時數據", itemX + 16, panelY + 10);

    fill(200);
    textSize(13);

    int showAnalog;
    float showNorm;
    String showFresh;

    if (bridge.calibrationDevice == 0) {
      showAnalog = bridge.extAnalog;
      showNorm = bridge.extAnalogNormalized();
      showFresh = bridge.extFresh() ? "更新中" : "未更新";
    } else {
      showAnalog = bridge.hoseAnalog;
      showNorm = bridge.hoseAnalogNormalized();
      showFresh = bridge.hoseFresh() ? "更新中" : "未更新";
    }

    text("目前校準裝置：" + calibrationLabel, itemX + 16, panelY + 32);
    text("控制狀態：" + controlLabel, itemX + 16, panelY + 52);
    text("目前遊戲藥劑：" + agentNames[currentAgent.ordinal()], itemX + 16, panelY + 72);

    text(calibrationLabel + "  Analog " + showAnalog
      + "   校準後 " + nf(showNorm, 0, 2),
      itemX + 16, panelY + 98);

    text("資料狀態：" + showFresh, itemX + 16, panelY + 124);

    float bw = 120, bh = 8;
    float bx = itemX + itemW - bw - 16;
    float barY = panelY + 40;
    fill(50);
    noStroke();
    rect(bx, barY, bw, bh, 3);
    fill(0, 200, 255);
    rect(bx, barY, bw * showNorm, bh, 3);
  }

  fill(0, 255, 100);
  textAlign(CENTER, BOTTOM);
  textSize(16);
  text("按 [R] 返回主畫面", width/2, height - 30);

  popStyle();
}

void handleSettingsKey() {
  if (bridge == null) return;
  int count = 5;

  if (keyCode == UP) {
    settingsIdx = (settingsIdx - 1 + count) % count;

  } else if (keyCode == DOWN) {
    settingsIdx = (settingsIdx + 1) % count;

  } else if (keyCode == LEFT || keyCode == RIGHT) {
    int dir = (keyCode == RIGHT) ? 1 : -1;
    switch (settingsIdx) {
      case 0:
        if (!bridge.connected && bridge.portList.length > 0)
          bridge.portIndex = (bridge.portIndex + dir + bridge.portList.length) % bridge.portList.length;
        break;
      case 1:
        bridge.calibrationDevice = 1 - bridge.calibrationDevice;
        break;
      case 2:
        if (bridge.calibrationDevice == 0) {
          bridge.extEnabled = !bridge.extEnabled;
        } else {
          bridge.hoseEnabled = !bridge.hoseEnabled;
        }
        if (bridge.ready) bridge.syncEnabledState();
        break;
    }

  } else if (key == ENTER || key == RETURN) {
    switch (settingsIdx) {
      case 0:
        if (bridge.connected) {
          bridge.disconnect();
        } else {
          bridge.refreshPorts();
          bridge.connect();
        }
        break;
      case 3:
        if (bridge.ready) bridge.calibrateAnalogMin();
        break;
      case 4:
        if (bridge.ready) bridge.calibrateAnalogMax();
        break;
    }
  }
}

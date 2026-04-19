#include <Wire.h>
#include "Device.h"

FireExtinguisher extinguisher(0x69, A0); // High
FireHose hose(0x68, A1); // Low

unsigned long prevTime = 0, lastSend = 0;
unsigned long sendInterval = 50;
bool configured = false;

void handleCommand(String cmd) {
  int sep = cmd.indexOf(':');
  if (sep < 0) return;

  String key = cmd.substring(0, sep);
  int val = cmd.substring(sep + 1).toInt();

  if (key == "interval") sendInterval = constrain(val, 10, 1000);
  else if (key == "ext") extinguisher.setEnabled(val);
  else if (key == "hose") hose.setEnabled(val);
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
  extinguisher.begin();
  hose.begin();
  delay(100);

  // 持續送 ready 直到 Processing 回應 cfg:ok
  while (!configured) {
    Serial.println("ready");
    delay(200);
    while (Serial.available()) {
      String line = Serial.readStringUntil('\n');
      line.trim();
      if (line == "cfg:ok") {
        configured = true;
      } else {
        handleCommand(line);
      }
    }
  }

  prevTime = millis();
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    handleCommand(cmd);
  }

  unsigned long now = millis();
  float dt = (now - prevTime) / 1000.0;
  prevTime = now;
  if (dt <= 0 || dt > 0.5) dt = 0.02;

  extinguisher.update(dt);
  hose.update(dt);

  if (now - lastSend >= sendInterval) {
    lastSend = now;
    bool first = true;
    if (extinguisher.enabled()) {
      extinguisher.serialize(Serial);
      first = false;
    }
    if (hose.enabled()) {
      if (!first) Serial.print('|');
      hose.serialize(Serial);
    }
    Serial.println();
  }
}
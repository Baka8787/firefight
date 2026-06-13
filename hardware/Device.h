#pragma once
#include "AnalogSensor.h"

class Device {
protected:
  const char* _id;
  AnalogSensor _analog;
  bool _enabled = true;

public:
  Device(const char* id, byte analogPin)
    : _id(id), _analog(analogPin) {}

  void begin() {
    _analog.begin();
  }

  void update() {
    if (!_enabled) return;
    _analog.update();
  }

  void serialize(Print &out) {
    out.print(_id);
    out.print(':');
    out.print(_analog.value());
  }

  void setEnabled(int val) { _enabled = (val != 0); }
  bool enabled() const { return _enabled; }
};

class FireExtinguisher : public Device {
public:
  FireExtinguisher(byte pressurePin)
    : Device("ext", pressurePin) {}

  int pressure() const { return _analog.value(); }
};

class FireHose : public Device {
public:
  FireHose(byte dialPin)
    : Device("hose", dialPin) {}

  int dial() const { return _analog.value(); }
};
#pragma once
#include "MPUSensor.h"
#include "AnalogSensor.h"

class Device {
protected:
  const char* _id;
  MPUSensor _mpu;
  AnalogSensor _analog;
  bool _enabled = true;

public:
  Device(const char* id, byte mpuAddr, byte analogPin)
    : _id(id), _mpu(mpuAddr), _analog(analogPin) {}

  void begin() {
    _mpu.begin();
    _analog.begin();
  }

  void update(float dt) {
    if (!_enabled) return;
    _analog.update();
    _mpu.update(dt);
  }

  void serialize(Print &out) {
    out.print(_id);
    out.print(':');
    out.print(_mpu.pitch(), 2); out.print(',');
    out.print(_mpu.roll(), 2);  out.print(',');
    out.print(_analog.value());
  }

  void setEnabled(int val) { _enabled = (val != 0); }
  bool enabled() const { return _enabled; }
};

class FireExtinguisher : public Device {
public:
  FireExtinguisher(byte mpuAddr, byte pressurePin)
    : Device("ext", mpuAddr, pressurePin) {}

  int pressure() const { return _analog.value(); }
};

class FireHose : public Device {
public:
  FireHose(byte mpuAddr, byte dialPin)
    : Device("hose", mpuAddr, dialPin) {}

  int dial() const { return _analog.value(); }
};
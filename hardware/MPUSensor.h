#pragma once
#include <Wire.h>

class MPUSensor {
  byte _addr;
  float _pitch = 0, _roll = 0;
  float _alpha; // 互補濾波係數，越大越信任陀螺儀

  void writeReg(byte reg, byte val) {
    Wire.beginTransmission(_addr);
    Wire.write(reg);
    Wire.write(val);
    Wire.endTransmission(true);
  }

public:
  MPUSensor(byte addr, float alpha = 0.96) : _addr(addr), _alpha(alpha) {}

  void begin() {
    writeReg(0x6B, 0x00); // 解除休眠
    writeReg(0x1C, 0x00); // 加速度計 ±2g
    writeReg(0x1B, 0x00); // 陀螺儀 ±250°/s
    writeReg(0x1A, 0x03); // 低通濾波 ~44Hz
  }

  bool update(float dt) {
    Wire.beginTransmission(_addr);
    Wire.write(0x3B); // 從 ACCEL_XOUT_H 開始連續讀 14 bytes
    Wire.endTransmission(false);
    Wire.requestFrom(_addr, (byte)14, (byte)true);

    int16_t ax = (Wire.read()<<8)|Wire.read();
    int16_t ay = (Wire.read()<<8)|Wire.read();
    int16_t az = (Wire.read()<<8)|Wire.read();
    Wire.read(); Wire.read(); // 跳過溫度暫存器
    int16_t gx = (Wire.read()<<8)|Wire.read();
    int16_t gy = (Wire.read()<<8)|Wire.read();
    int16_t gz = (Wire.read()<<8)|Wire.read();

    float accP = atan2(ax, sqrt((long)ay*ay + (long)az*az)) * RAD_TO_DEG;
    float accR = atan2(ay, sqrt((long)ax*ax + (long)az*az)) * RAD_TO_DEG;

    // 131 = ±250°/s 量程下的靈敏度 (LSB/°/s)
    _pitch = _alpha * (_pitch + gx/131.0*dt) + (1-_alpha) * accP;
    _roll  = _alpha * (_roll  + gy/131.0*dt) + (1-_alpha) * accR;

    // 接觸不良會產生 NaN，自動重新初始化
    if (isnan(_pitch) || isnan(_roll)) {
      _pitch = 0; _roll = 0;
      begin();
      delay(50);
      return false;
    }
    return true;
  }

  float pitch() const { return _pitch; }
  float roll()  const { return _roll; }
};
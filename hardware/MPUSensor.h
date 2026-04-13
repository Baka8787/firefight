#pragma once
#include <Wire.h>

class MPUSensor {
  byte _addr;
  float _pitch = 0, _roll = 0, _yaw = 0;
  float _pitchRate = 0, _rollRate = 0, _yawRate = 0;
  float _gyroBiasX = 0, _gyroBiasY = 0, _gyroBiasZ = 0;
  float _alpha; // 互補濾波係數

  void writeReg(byte reg, byte val) {
    Wire.beginTransmission(_addr);
    Wire.write(reg);
    Wire.write(val);
    Wire.endTransmission(true);
  }

  bool readRaw(int16_t &ax, int16_t &ay, int16_t &az,
               int16_t &gx, int16_t &gy, int16_t &gz) {
    Wire.beginTransmission(_addr);
    Wire.write(0x3B);
    if (Wire.endTransmission(false) != 0) return false;

    byte n = Wire.requestFrom(_addr, (byte)14, (byte)true);
    if (n != 14) return false;

    ax = (Wire.read()<<8)|Wire.read();
    ay = (Wire.read()<<8)|Wire.read();
    az = (Wire.read()<<8)|Wire.read();
    Wire.read(); Wire.read(); // 跳過溫度暫存器
    gx = (Wire.read()<<8)|Wire.read();
    gy = (Wire.read()<<8)|Wire.read();
    gz = (Wire.read()<<8)|Wire.read();
    return true;
  }

  void calibrateGyroBias() {
    long sumX = 0, sumY = 0, sumZ = 0;
    const int samples = 300;

    for (int i = 0; i < samples; i++) {
      int16_t ax, ay, az, gx, gy, gz;
      if (readRaw(ax, ay, az, gx, gy, gz)) {
        sumX += gx;
        sumY += gy;
        sumZ += gz;
      }
      delay(2);
    }

    _gyroBiasX = (sumX / (float)samples) / 131.0;
    _gyroBiasY = (sumY / (float)samples) / 131.0;
    _gyroBiasZ = (sumZ / (float)samples) / 131.0;
  }

public:
  MPUSensor(byte addr, float alpha = 0.985) : _addr(addr), _alpha(alpha) {}

  void begin() {
    writeReg(0x6B, 0x00);
    writeReg(0x1C, 0x00);
    writeReg(0x1B, 0x00);
    writeReg(0x1A, 0x04);
    delay(100);
    calibrateGyroBias();
  }

  bool update(float dt) {
    int16_t ax, ay, az, gx, gy, gz;
    if (!readRaw(ax, ay, az, gx, gy, gz)) {
      begin();
      delay(50);
      return false;
    }

    float gyroX = gx / 131.0 - _gyroBiasX;
    float gyroY = gy / 131.0 - _gyroBiasY;
    float gyroZ = gz / 131.0 - _gyroBiasZ;

    _pitchRate = _pitchRate * 0.85 + gyroX * 0.15;
    _rollRate  = _rollRate  * 0.85 + gyroY * 0.15;
    _yawRate   = _yawRate   * 0.85 + gyroZ * 0.15;

    float accP = atan2(ax, sqrt((long)ay*ay + (long)az*az)) * RAD_TO_DEG;
    float accR = atan2(ay, sqrt((long)ax*ax + (long)az*az)) * RAD_TO_DEG;

    float newPitch = _alpha * (_pitch + _pitchRate * dt) + (1 - _alpha) * accP;
    float newRoll  = _alpha * (_roll  + _rollRate  * dt) + (1 - _alpha) * accR;
    float newYaw = _yaw + _yawRate * dt;

    _pitch = _pitch * 0.88 + newPitch * 0.12;
    _roll  = _roll  * 0.88 + newRoll  * 0.12;
    _yaw = _yaw * 0.88 + newYaw * 0.12;


    if (isnan(_pitch) || isnan(_roll) || isnan(_yaw)) {
      _pitch = 0; _roll = 0; _yaw = 0;
      _pitchRate = 0; _rollRate = 0; _yawRate = 0;
      begin();
      delay(50);
      return false;
    }
    return true;
  }

  float pitch() const { return _pitch; }
  float roll()  const { return _roll; }
  float yaw()   const { return _yaw; }
  float pitchRate() const { return _pitchRate; }
  float rollRate()  const { return _rollRate; }
  float yawRate()   const { return _yawRate; }
};
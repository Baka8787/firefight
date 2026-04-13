#pragma once

class AnalogSensor {
  byte _pin;
  int _value = 0;
  int _buffer[8] = {}; // 8 點移動平均濾波
  byte _idx = 0;
  bool _filled = false;

public:
  AnalogSensor(byte pin) : _pin(pin) {}

  void begin() { pinMode(_pin, INPUT); }

  void update() {
    _buffer[_idx] = analogRead(_pin);
    _idx = (_idx + 1) % 8;
    if (_idx == 0) _filled = true;

    // 緩衝區未滿時只算已填入的部分
    long sum = 0;
    byte count = _filled ? 8 : _idx;
    for (byte i = 0; i < count; i++) sum += _buffer[i];
    _value = sum / count;
  }

  int value() const { return _value; }        // 0~1023
  float normalized() const { return _value / 1023.0; } // 0.0~1.0
};
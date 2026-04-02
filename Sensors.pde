/**
 * Sensors.pde
 * 感測器介面層：隔離硬體輸入，之後換真實感測器只改這裡
 */

// 濾波緩衝區
float[] sensorBuffer = new float[10];
int bufferIndex = 0;

/**
 * 取得原始感測器數據
 * 目前用滑鼠模擬：按下 = 高壓力，放開 = 低壓力
 * 換接硬體時只需替換此函式內容
 */
float getSensorData() {
  return mousePressed ? 800 : 100;
}

/**
 * 判斷使用者是否正在按壓握把
 */
boolean isPressing() {
  return mousePressed;
}

/**
 * 取得濾波後的感測器數據（移動平均濾波）
 * 減少硬體雜訊對噴灑半徑的影響
 */
float getFilteredSensorData() {
  float raw = getSensorData();
  sensorBuffer[bufferIndex] = raw;
  bufferIndex = (bufferIndex + 1) % sensorBuffer.length;

  float sum = 0;
  for (float v : sensorBuffer) sum += v;
  return sum / sensorBuffer.length;
}
/**
 * Colors.pde
 * 統一管理 UI 配色方案，方便後期調整與維護
 * 設計風格：現代簡約 + HUD 工程風
 */

// ============================================
// 主色調定義
// ============================================

// 背景與邊框色
final color BG_DARK           = color(15, 15, 25);     // 極暗藍色背景
final color BG_SEMI_DARK      = color(30, 30, 40);     // 深灰藍
final color BORDER_SUBTLE     = color(255, 80);        // 極細邊框（半透明）
final color OVERLAY_DARK      = color(0, 0, 0, 180);   // 深色遮罩

// 主要突強色
final color ACCENT_CYAN       = color(60, 200, 255);   // 科技藍
final color ACCENT_YELLOW     = color(255, 255, 160);  // 米黃色（主標題用）
final color ACCENT_GREEN      = color(100, 220, 150);  // 亮綠色（成功用）

// 警告與狀態色
final color STATUS_SUCCESS    = color(100, 220, 150);  // 綠色成功
final color STATUS_DANGER     = color(255, 100, 100);  // 柔紅色警告
final color STATUS_WARNING    = color(255, 200, 100);  // 米黃色提示
final color STATUS_CRITICAL   = color(255, 50, 50);    // 深紅色緊急

// 文字色
final color TEXT_PRIMARY      = color(255);            // 純白
final color TEXT_SECONDARY    = color(200, 200, 200);  // 淡灰
final color TEXT_WEAK         = color(150, 150, 150);  // 弱灰
final color TEXT_TERTIARY     = color(100, 100, 100);  // 深灰

// 進度條相關
final color BAR_BG            = color(30);              // 進度條背景
final color BAR_PROGRESS_OK   = color(100, 255, 150);  // 綠色進度條
final color BAR_PROGRESS_WARN = color(255, 150, 100);  // 橙色進度條

// 資訊區塊背景
final color INFO_BLOCK_BG     = color(0, 0, 0, 150);   // 半透明黑背景

// ============================================
// 火災類型色彩
// ============================================

color getFireTypeColor(FireType type) {
  switch(type) {
    case GENERAL:    return color(255, 180, 100);      // 橙黃色
    case ELECTRICAL: return color(150, 200, 255);      // 電藍色
    case OIL:        return color(255, 150, 100);      // 柔橙色
    case METAL:      return color(200, 150, 255);      // 紫色
    default:         return color(200, 200, 200);
  }
}

// ============================================
// 藥劑類型色彩
// ============================================

color getAgentColor(Agent agent) {
  switch(agent) {
    case WATER:   return color(60, 180, 255);          // 水藍
    case POWDER:  return color(200, 150, 100);         // 粉土色
    case CO2:     return color(200, 200, 200);         // 銀灰色
    case METAL:   return color(255, 200, 100);         // 金黃色
    default:      return color(150, 150, 150);
  }
}

// ============================================
// 評級色彩
// ============================================

color getGradeColor(String grade) {
  switch(grade) {
    case "A":  return color(100, 220, 150);            // 亮綠
    case "B":  return color(255, 200, 100);            // 米黃
    case "C":  return color(255, 150, 100);            // 柔橙
    case "F":  return color(255, 80, 80);              // 深紅
    default:   return color(150, 150, 150);
  }
}

// ============================================
// 高級色彩混合函式（後期可供擴展）
// ============================================

/**
 * 根據健康度返回相應的警告色
 * @param health 當前健康值 (0-100)
 * @return 對應的顏色
 */
color getHealthColor(float health) {
  if (health > 60) {
    return color(100, 255, 150); // 綠色
  } else if (health > 30) {
    return color(255, 200, 100); // 黃色
  } else {
    return color(255, 100, 100); // 紅色
  }
}

/**
 * 時間緊急度色彩
 * @param remainTime 剩餘時間
 * @param totalTime 總時間
 * @return 對應的顏色
 */
color getTimerColor(int remainTime, int totalTime) {
  float ratio = (float)remainTime / totalTime;
  if (ratio > 0.5) {
    return color(150, 200, 255); // 藍色（寬鬆）
  } else if (ratio > 0.25) {
    return color(255, 200, 100); // 黃色（中等）
  } else {
    return color(255, 100, 100); // 紅色（緊急）
  }
}

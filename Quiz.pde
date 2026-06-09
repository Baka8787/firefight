/**
 * Quiz.pde
 * 處理 5 個問答題的邏輯、UI 繪製與成績結算
 答案:a,a,c,c,b
 */

// 定義題目資料結構
class Question {
  String qText;
  String[] options;
  int correctIdx;
  String explanation;

  Question(String q, String[] opts, int cIdx, String exp) {
    qText = q;
    options = opts;
    correctIdx = cIdx;
    explanation = exp;
  }
}

ArrayList<Question> quizQuestions = new ArrayList<Question>();
int currentQIndex = 0;
int correctAnswers = 0;
boolean showingExplanation = false;
int userChoice = -1;
boolean quizCompleted = false;

/**
 * 初始化測驗（每次點擊「5個問答」時呼叫）
 */
void initQuiz() {
  quizQuestions.clear();
  currentQIndex = 0;
  correctAnswers = 0;
  showingExplanation = false;
  userChoice = -1;
  quizCompleted = false;

  // 載入你的 5 個題目
  quizQuestions.add(new Question(
    "1. 哪一種燃燒物質引起的火災屬於「A類火災（普通火災）」？",
    new String[]{"木材、紙張或棉布", "鎂粉、鈉或鉀金屬", "通電中的變壓器或馬達", "汽油、酒精或機油"},
    0, // A
    "沒錯！木材、紙張、紡織品等一般固體可燃物引起的火災屬於A類火災，通常可藉由水來冷卻撲滅。"
  ));

  quizQuestions.add(new Question(
    "2. 若發生B類（油脂類）火災，下列哪一種滅火方式或藥劑最不適合且可能造成危險？",
    new String[]{"直接噴射柱狀清水", "使用二氧化碳滅火器", "使用泡沫滅火器", "使用乾粉滅火器"},
    0, // A
    "沒錯！油的密度小於水，直接噴射水柱會導致燃燒的油浮在水面上四處流竄，使火勢迅速擴大。"
  ));

  quizQuestions.add(new Question(
    "3. 在機房中，運作中的電腦伺服器因短路而引發火勢。這在分類上屬於哪一類火災？",
    new String[]{"A類火災", "D類火災", "C類火災", "B類火災"},
    2, // C
    "答對了！涉及通電中電氣設備的火災屬於C類，必須使用不導電的滅火劑（如二氧化碳或乾粉）來處理，避免觸電危險。"
  ));

  quizQuestions.add(new Question(
    "4. D類（金屬）火災通常涉及如鎂、鈉、鉀等禁水性物質。撲滅這類火災應使用下列何種器材或方式？",
    new String[]{"使用二氧化碳滅火系統", "使用一般ABC乾粉滅火器", "使用金屬火災專用特種乾粉或乾燥砂土", "使用大量清水降溫"},
    2, // C
    "沒錯！這類火災必須使用專用的D類特種金屬滅火劑或乾燥砂土，透過完全覆蓋來阻絕氧氣並吸收熱量。"
  ));

  quizQuestions.add(new Question(
    "5. 在一座化學工廠中，存放了大量的甲苯與丙酮等有機溶劑。若這些溶劑不慎外洩並引發火災，消防人員應針對哪一類火災進行搶救？",
    new String[]{"A類火災", "B類火災", "C類火災", "D類火災"},
    1, // B
    "答對了！化學溶劑屬於易燃液體，符合此分類的定義，通常需要使用泡沫或化學乾粉來阻絕氧氣。"
  ));
}

/**
 * 繪製測驗畫面
 */
void drawQuizScreen() {
  pushStyle();
  fill(OVERLAY_DARK); // 延續 UI.pde 的半透明深色遮罩
  rect(0, 0, width, height);

  textFont(mainFont);

  // === 結算畫面 ===
  if (quizCompleted) {
    textAlign(CENTER, CENTER);
    fill(ACCENT_YELLOW);
    textSize(48);
    text("消防問答測驗結束！", width/2, height/2 - 120);

    // 計算正確率
    float accuracy = (float)correctAnswers / quizQuestions.size() * 100;
    
    fill(255);
    textSize(32);
    text("答對題數: " + correctAnswers + " / " + quizQuestions.size(), width/2, height/2 - 20);

    // 依據正確率改變顏色
    if (accuracy == 100) fill(STATUS_SUCCESS);
    else if (accuracy >= 60) fill(STATUS_WARNING);
    else fill(STATUS_DANGER);

    textSize(80);
    text("正確率: " + int(accuracy) + "%", width/2, height/2 + 70);

    fill(TEXT_WEAK);
    textSize(20);
    text("▶ 按 [R] 鍵返回主畫面 ◀", width/2, height - 60);
    popStyle();
    return;
  }

  // === 測驗進行中畫面 ===
  Question q = quizQuestions.get(currentQIndex);

  // 1. 繪製頂部進度與題目
  fill(ACCENT_CYAN);
  textAlign(LEFT, TOP);
  textSize(24);
  text("消防知識問答 (" + (currentQIndex + 1) + "/5)", 100, 60);

  fill(255);
  textSize(28);
  text(q.qText, 100, 110, width - 200, 100); // 支援自動換行

  float startY = 220; // 選項或解析的起始 Y 座標
  String[] prefixes = {"A", "B", "C", "D"};

  if (!showingExplanation) {
    // ---------------------------------------------------------
    // 狀態 A：作答中 (只顯示四個選項按鈕)
    // ---------------------------------------------------------
    float optHeight = 65;
    float optSpacing = 20;

    for (int i = 0; i < 4; i++) {
      float by = startY + i * (optHeight + optSpacing);
      boolean isHover = (mouseX >= 100 && mouseX <= width - 100 && mouseY >= by && mouseY <= by + optHeight);

      // 正在作答時的 Hover 特效
      if (isHover) fill(60, 120, 180);
      else fill(INFO_BLOCK_BG);

      stroke(BORDER_SUBTLE);
      strokeWeight(2);
      rect(100, by, width - 200, optHeight, 12);

      fill(255);
      textAlign(LEFT, CENTER);
      textSize(24);
      text(prefixes[i] + ". " + q.options[i], 130, by + optHeight/2 - 4);
    }

  } else {
    // ---------------------------------------------------------
    // 狀態 B：已作答 (隱藏選項，顯示解析與下一題按鈕)
    // ---------------------------------------------------------
    
    // 顯示對錯狀態與正確答案提示
    textSize(32);
    textAlign(LEFT, TOP);
    if (userChoice == q.correctIdx) {
      fill(STATUS_SUCCESS);
      text("✅ 正確！", 100, startY);
    } else {
      fill(STATUS_DANGER);
      text("❌ 錯誤！正確選項是 " + prefixes[q.correctIdx], 100, startY);
    }

    // 顯示大括號內的完整解析
    fill(ACCENT_YELLOW);
    textSize(24);
    // 留出充分的高度空間 (250px) 讓文字自動換行，不會被裁切
    text("解析：" + q.explanation, 100, startY + 60, width - 200, 250);

    // 繪製「下一題」按鈕
    float nextBtnW = 220;
    float nextBtnH = 60;
    float nextBtnX = width/2 - nextBtnW/2;
    float nextBtnY = startY + 220; // 固定在解析文字下方
    boolean nextHover = (mouseX >= nextBtnX && mouseX <= nextBtnX + nextBtnW && mouseY >= nextBtnY && mouseY <= nextBtnY + nextBtnH);

    if (nextHover) fill(STATUS_SUCCESS);
    else fill(40, 150, 80);

    stroke(255);
    strokeWeight(2);
    rect(nextBtnX, nextBtnY, nextBtnW, nextBtnH, 30);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(26);
    text(currentQIndex == 4 ? "查看最終成績" : "前往下一題", nextBtnX + nextBtnW/2, nextBtnY + nextBtnH/2 - 4);
  }

  popStyle();
}

/**
 * 處理測驗畫面中的滑鼠點擊
 */
void handleQuizClick() {
  if (quizCompleted) return;

  Question q = quizQuestions.get(currentQIndex);
  float startY = 220;

  if (showingExplanation) {
    // 狀態為顯示解析時，只能點擊「下一題」按鈕
    float nextBtnW = 220;
    float nextBtnH = 60;
    float nextBtnX = width/2 - nextBtnW/2;
    float nextBtnY = startY + 220; // 必須與 drawQuizScreen 中的座標一致

    if (mouseX >= nextBtnX && mouseX <= nextBtnX + nextBtnW && mouseY >= nextBtnY && mouseY <= nextBtnY + nextBtnH) {
      if (currentQIndex < 4) {
        currentQIndex++; // 進入下一題
        showingExplanation = false;
        userChoice = -1;
      } else {
        quizCompleted = true; // 進入結算畫面
      }
    }
  } else {
    // 狀態為作答時，偵測點擊了哪個選項 (A, B, C, D)
    float optHeight = 65;
    float optSpacing = 20;

    for (int i = 0; i < 4; i++) {
      float by = startY + i * (optHeight + optSpacing);
      if (mouseX >= 100 && mouseX <= width - 100 && mouseY >= by && mouseY <= by + optHeight) {
        userChoice = i; // 紀錄使用者點擊的選項
        showingExplanation = true; // 開啟解析模式，這會觸發選項消失
        
        // 若選中正確答案，正確數 +1
        if (userChoice == q.correctIdx) {
          correctAnswers++;
        }
        break; // 找到點擊的按鈕就跳出迴圈
      }
    }
  }
}

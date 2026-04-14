class ScoreCalculator {
  static int calculateStepScore({
    required bool isCorrect,
    required String level,
    required bool isReviewMode,
    int comboCount = 0,
  }) {
    // 1. Temel Puanlar
    int basePoint = isReviewMode ? 6 : 10;
    int penaltyPoint = isReviewMode ? 3 : 6;

    // 2. Seviye Katsayısı (Multiplier)
    double multiplier = 1.0;
    final upperLevel = level.toUpperCase();
    if (upperLevel.startsWith('B')) {
      multiplier = 1.5;
    } else if (upperLevel.startsWith('C')) {
      multiplier = 2.5;
    }

    if (isCorrect) {
      // Doğru puanı + Combo Bonusu (Sadece Normal Modda her 5 doğruda bir)
      int comboBonus = (!isReviewMode && comboCount > 0 && comboCount % 5 == 0) ? 10 : 0;
      return (basePoint * multiplier).toInt() + comboBonus;
    } else {
      // Yanlış cezası (Negatif döner)
      return -(penaltyPoint * multiplier).toInt();
    }
  }
}
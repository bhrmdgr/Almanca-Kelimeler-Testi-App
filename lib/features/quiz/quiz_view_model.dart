import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ✅ Importlar İngilizce projesiyle aynı yapıya getirildi
import 'package:almanca_kelime_testi/features/quiz/quiz_model.dart';
import 'package:almanca_kelime_testi/service/admob/admob_service.dart'; // Eksikti, eklendi
import 'package:almanca_kelime_testi/service/firebase/leaderboard_service.dart';
import 'package:almanca_kelime_testi/service/firebase/stats_service.dart';

// ✅ Almanca yönleri (deToTr, trToDe)
enum QuizQuestionMode { deToTr, trToDe, random }

class QuizViewModel extends ChangeNotifier {
  final StatsService _statsService = StatsService();
  final LeaderboardService _leaderboardService = LeaderboardService();

  List<WordModel> _allWords = [];
  bool isLoading = false;

  // --- Quiz Ayarları ---
  int selectedQuestionCount = 10;
  String selectedLevel = 'A1';
  String selectedType = 'all';
  QuizQuestionMode selectedQuestionMode = QuizQuestionMode.deToTr;

  // --- Reklam Sayaçları ---
  // ✅ İngilizce'deki toplam soru bazlı reklam mantığı aktarıldı
  int _totalQuestionCounter = 0;

  final List<int> questionCounts = [10, 20, 30, 40];
  final List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  // ✅ Almanca tür isimleri (Dilersen İngilizce ile aynı tutup sadece UI'da Türkçeleştirebilirsin ama kodda bunlar kullanılıyor)
  final List<String> types = ['all', 'noun', 'verb', 'adjective', 'adverb'];

  // --- Quiz Anlık Durum Verileri ---
  int currentQuestionIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;
  List<WordModel> learnedWords = [];
  List<WordModel> wrongWords = [];
  List<String> currentOptions = [];
  bool isCurrentQuestionDeToTr = true; // ✅ DE -> TR yönü

  int currentScore = 0;
  int comboCount = 0;
  int lastEarnedPoints = 0;

  // ✅ Reklam Mantığı (İngilizce ile birebir aynı: 30 soru eşiği)
  bool shouldShowInterstitialAd(int currentQuizLength) {
    _totalQuestionCounter += currentQuizLength;

    if (_totalQuestionCounter >= 30) {
      _totalQuestionCounter = 0;
      return true;
    }
    return false;
  }

  Future<void> fetchWords() async {
    isLoading = true;
    notifyListeners();

    try {
      String fileName = _getFileNameByLevel(selectedLevel);
      final String response = await rootBundle.loadString('assets/data/$fileName');
      final List<dynamic> data = json.decode(response);

      // ✅ Kelime map'leme mantığı İngilizce ile aynı (word.de kontrolüyle)
      _allWords = data
          .where((item) => item.containsKey('de'))
          .map((json) => WordModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("Kelime yükleme hatası ($selectedLevel): $e");
      _allWords = [];
    }

    isLoading = false;
    notifyListeners();
  }

  String _getFileNameByLevel(String level) {
    switch (level.toUpperCase()) {
      case 'A1': return 'a_one_words.json';
      case 'A2': return 'a_two_words.json';
      case 'B1': return 'b_one_words.json';
      case 'B2': return 'b_two_words.json';
      case 'C1': return 'c_one_words.json';
      case 'C2': return 'c_two_words.json';
      default: return 'a_one_words.json';
    }
  }

  void setQuestionCount(int count) {
    selectedQuestionCount = count;
    notifyListeners();
  }

  void setLevel(String level) {
    if (selectedLevel != level) {
      selectedLevel = level;
      fetchWords();
      notifyListeners();
    }
  }

  void setType(String type) {
    selectedType = type;
    notifyListeners();
  }

  void setQuestionMode(QuizQuestionMode mode) {
    selectedQuestionMode = mode;
    notifyListeners();
  }


  List<WordModel> generateQuizList() {
    debugPrint("Filtreleme Başladı: Seviye: $selectedLevel, Tür: $selectedType");

    List<WordModel> filtered = _allWords.where((w) {
      // Seviye eşleşmesi (Boşlukları siler ve büyük harfe çevirir)
      bool levelMatch = w.level.trim().toUpperCase() == selectedLevel.trim().toUpperCase();

      // Tür eşleşmesi (all ise hepsi, değilse JSON içindeki type değerinde arama yapar)
      // w.type 'adjective' ise ve selectedType 'adjective' ise eşleşir.
      bool typeMatch = selectedType == 'all' ||
          w.type.toLowerCase().trim().contains(selectedType.toLowerCase().trim());

      return levelMatch && typeMatch;
    }).toList();

    debugPrint("Sonuç: ${filtered.length} kelime bulundu.");

    filtered.shuffle();
    return filtered.take(selectedQuestionCount).toList();
  }
  Future<void> generateOptions(WordModel correctWord) async {
    if (_allWords.isEmpty) {
      selectedLevel = correctWord.level;
      await fetchWords();
    }

    // ✅ Soru yönü belirleme
    if (selectedQuestionMode == QuizQuestionMode.deToTr) {
      isCurrentQuestionDeToTr = true;
    } else if (selectedQuestionMode == QuizQuestionMode.trToDe) {
      isCurrentQuestionDeToTr = false;
    } else {
      isCurrentQuestionDeToTr = Random().nextBool();
    }

    String correctAnswer = isCurrentQuestionDeToTr ? correctWord.tr : correctWord.de;

    List<String> options = [correctAnswer];
    List<WordModel> potentialDistractors = List.from(_allWords);
    potentialDistractors.shuffle();

    for (var word in potentialDistractors) {
      String distractor = isCurrentQuestionDeToTr ? word.tr : word.de;

      if (options.length < 4 &&
          distractor != correctAnswer &&
          !options.contains(distractor)) {

        if (selectedType != 'all') {
          if (word.type.toLowerCase() == correctWord.type.toLowerCase()) {
            options.add(distractor);
          }
        } else {
          options.add(distractor);
        }
      }
    }

    // Seçenekler eksik kalırsa tamamla
    if (options.length < 4) {
      for (var word in potentialDistractors) {
        String distractor = isCurrentQuestionDeToTr ? word.tr : word.de;
        if (options.length < 4 && distractor != correctAnswer && !options.contains(distractor)) {
          options.add(distractor);
        }
      }
    }

    options.shuffle();
    currentOptions = options;
    notifyListeners();
  }

  void answerQuestion(WordModel word, String selectedAnswer,
      {bool isReviewMode = false, bool isLearnedReview = false}) {

    String correctAnswer = isCurrentQuestionDeToTr ? word.tr : word.de;
    bool isCorrect = correctAnswer == selectedAnswer;

    if (isCorrect) {
      correctCount++;
      comboCount++; // ✅ Seri bonusu için artış
      if (!isLearnedReview) learnedWords.add(word);
    } else {
      wrongCount++;
      comboCount = 0; // ✅ Seri sıfırlanır
      wrongWords.add(word);
    }

    int basePoint;
    int penaltyPoint;

    if (isLearnedReview) {
      basePoint = 4;
      penaltyPoint = 2;
    } else if (isReviewMode) {
      basePoint = 6;
      penaltyPoint = 3;
    } else {
      basePoint = 10;
      penaltyPoint = 6;
    }

    double multiplier = 1.0;
    String lvl = word.level.toUpperCase();
    if (lvl.startsWith('B')) multiplier = 1.5;
    if (lvl.startsWith('C')) multiplier = 2.5;

    if (isCorrect) {
      lastEarnedPoints = (basePoint * multiplier).toInt();
      // ✅ SERİ BONUSU AKTARILDI: 5. doğrudan itibaren her soruya +3 prim
      if (!isReviewMode && !isLearnedReview && comboCount >= 5) {
        lastEarnedPoints += 3;
      }
    } else {
      lastEarnedPoints = -(penaltyPoint * multiplier).toInt();
    }

    currentScore += lastEarnedPoints;
    if (currentScore < 0) currentScore = 0;

    notifyListeners();
  }

  Future<void> nextQuestion(List<WordModel> quizList) async {
    if (currentQuestionIndex < quizList.length - 1) {
      currentQuestionIndex++;
      await generateOptions(quizList[currentQuestionIndex]);
      notifyListeners();
    }
  }

  Future<void> refreshQuizList() async {
    resetQuiz();
    List<WordModel> newList = generateQuizList();
    if (newList.isNotEmpty) {
      await generateOptions(newList[0]);
    }
    notifyListeners();
  }

  Future<void> uploadResults(int totalQuestionCount, {bool isReview = false}) async {
    isLoading = true;
    notifyListeners();

    try {
      // ✅ StatsService üzerinden tek Batch ile gönderim (İngilizce ile senkron)
      await _statsService.saveQuizResults(
        learnedWords: learnedWords,
        wrongWords: wrongWords,
        earnedPoints: currentScore,
        isReviewMode: isReview,
      );
    } catch (e) {
      debugPrint("Yükleme hatası: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void resetQuiz() {
    currentQuestionIndex = 0;
    correctCount = 0;
    wrongCount = 0;
    learnedWords = [];
    wrongWords = [];
    currentOptions = [];
    currentScore = 0;
    comboCount = 0;
    lastEarnedPoints = 0;
    notifyListeners();
  }
}
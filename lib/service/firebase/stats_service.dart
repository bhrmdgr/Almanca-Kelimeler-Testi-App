import 'dart:convert';
import 'package:almanca_kelime_testi/features/quiz/quiz_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? "";
  bool get _isGuest => _auth.currentUser?.isAnonymous ?? true;

  String _getWeeklyId() {
    DateTime now = DateTime.now();
    int dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1)).inDays.toString());
    int weekNum = ((dayOfYear - now.weekday + 10) / 7).floor();
    return "${now.year}-W${weekNum.toString().padLeft(2, '0')}";
  }

  // ✅ ANA METOD: Artık earnedPoints parametresini zorunlu olarak alıyor
  Future<void> saveQuizResults({
    required List<WordModel> learnedWords,
    required List<WordModel> wrongWords,
    required int earnedPoints,
    bool isReviewMode = false,
  }) async {
    if (_userId.isEmpty && !_isGuest) return;

    if (_isGuest) {
      // ✅ Alt metodlara doğru sırada gönderiyoruz
      await _saveToLocal(learnedWords, wrongWords, earnedPoints, isReviewMode);
    } else {
      await _saveToFirebase(learnedWords, wrongWords, earnedPoints, isReviewMode);
    }
  }

  // --- FIREBASE KAYIT MANTIĞI ---
  Future<void> _saveToFirebase(
      List<WordModel> learnedWords,
      List<WordModel> wrongWords,
      int earnedPoints, // ✅ Eklendi
      bool isReviewMode,
      ) async {
    final userDoc = _firestore.collection('users').doc(_userId);
    final leaderboardRef = _firestore.collection('leaderboard').doc(_userId);
    final weeklyLeaderboardRef = _firestore.collection('weekly_leaderboard').doc(_userId); // ✅ HAFTALIK REF EKLENDİ

    final now = DateTime.now();
    final dateId = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final dailyRef = userDoc.collection('daily_series').doc(dateId);

    WriteBatch batch = _firestore.batch();

    final userSnap = await userDoc.get();
    int currentStreak = userSnap.data()?['streak'] ?? 0;
    String? lastQuizDateStr = userSnap.data()?['last_quiz_date_str'];

    if (lastQuizDateStr == null) {
      currentStreak = 1;
    } else {
      DateTime lastDate = DateTime.parse(lastQuizDateStr);
      DateTime today = DateTime(now.year, now.month, now.day);
      int diff = today.difference(lastDate).inDays;

      if (diff == 1) {
        currentStreak += 1;
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }

    // ✅ ScoreCalculator SİLİNDİ, direkt gelen earnedPoints kullanılıyor.

    for (var word in learnedWords) {
      var learnedRef = userDoc.collection('learned_words').doc(word.de);
      batch.set(learnedRef, {
        ...word.toJson(),
        'last_updated': FieldValue.serverTimestamp(),
        'status': 'learned'
      });
      batch.delete(userDoc.collection('wrong_words').doc(word.de));
    }

    for (var word in wrongWords) {
      var wrongRef = userDoc.collection('wrong_words').doc(word.de);
      batch.set(wrongRef, {
        ...word.toJson(),
        'last_updated': FieldValue.serverTimestamp(),
        'status': 'struggling',
        'wrong_count': FieldValue.increment(1)
      });
      batch.delete(userDoc.collection('learned_words').doc(word.de));
    }

    batch.set(dailyRef, {
      'quiz_count': FieldValue.increment(1),
      'question_count': FieldValue.increment(learnedWords.length + wrongWords.length),
      'correct_answers': FieldValue.increment(learnedWords.length),
      'earned_points': FieldValue.increment(earnedPoints),
      'date': dateId,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userDoc, {
      'total_quiz_completed': FieldValue.increment(1),
      'last_quiz_date': FieldValue.serverTimestamp(),
      'last_quiz_date_str': dateId,
      'streak': currentStreak,
      'score': FieldValue.increment(earnedPoints),
      'weekly_score': FieldValue.increment(earnedPoints),
    }, SetOptions(merge: true));

    // ✅ GENEL LEADERBOARD GÜNCELLEME
    batch.set(leaderboardRef, {
      'uid': _userId,
      'username': userSnap.data()?['username'] ?? "Kullanıcı",
      'avatar': userSnap.data()?['avatarPath'], // Cloud functions ile uyum için key 'avatar' yapıldı
      'totalScore': FieldValue.increment(earnedPoints),
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ HAFTALIK LEADERBOARD GÜNCELLEME
    batch.set(weeklyLeaderboardRef, {
      'uid': _userId,
      'username': userSnap.data()?['username'] ?? "Kullanıcı",
      'avatar': userSnap.data()?['avatarPath'],
      'weeklyScore': FieldValue.increment(earnedPoints),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // --- LOCAL STORAGE (GUEST) KAYIT MANTIĞI ---
  Future<void> _saveToLocal(
      List<WordModel> learnedWords,
      List<WordModel> wrongWords,
      int earnedPoints, // ✅ Eklendi
      bool isReviewMode,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    List<String> localLearned = prefs.getStringList('guest_learned_words') ?? [];
    List<String> localWrong = prefs.getStringList('guest_wrong_words') ?? [];

    Map<String, String> learnedMap = {for (var s in localLearned) json.decode(s)['de']: s};
    Map<String, String> wrongMap = {for (var s in localWrong) json.decode(s)['de']: s};

    for (var word in learnedWords) {
      learnedMap[word.de] = json.encode(word.toJson());
      wrongMap.remove(word.de);
    }
    for (var word in wrongWords) {
      wrongMap[word.de] = json.encode(word.toJson());
      learnedMap.remove(word.de);
    }

    int totalWords = learnedMap.length + wrongMap.length;
    int accuracy = totalWords > 0 ? ((learnedMap.length / totalWords) * 100).toInt() : 0;
    await prefs.setInt('guest_accuracy', accuracy);

    int streak = prefs.getInt('guest_streak') ?? 0;
    String? lastDate = prefs.getString('guest_last_quiz_date');
    if (lastDate == null) {
      streak = 1;
    } else {
      int diff = DateTime.parse(todayStr).difference(DateTime.parse(lastDate)).inDays;
      if (diff == 1) streak++;
      else if (diff > 1) streak = 1;
    }

    int currentTotalScore = prefs.getInt('guest_score') ?? 0;
    await prefs.setInt('guest_score', currentTotalScore + earnedPoints);

    await prefs.setStringList('guest_learned_words', learnedMap.values.toList());
    await prefs.setStringList('guest_wrong_words', wrongMap.values.toList());
    await prefs.setInt('guest_streak', streak);
    await prefs.setString('guest_last_quiz_date', todayStr);

    int currentCompleted = prefs.getInt('guest_completed_tasks') ?? 0;
    await prefs.setInt('guest_completed_tasks', currentCompleted + learnedWords.length);
  }

  // Hibrit Stream ve diğer yardımcı metodlar değişmeden kalıyor...
  Stream<List<WordModel>> getLearnedWords() {
    if (_isGuest) return _getLocalWordsStream('guest_learned_words');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('learned_words')
        .orderBy('last_updated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WordModel.fromJson(doc.data())).toList());
  }

  Stream<List<WordModel>> getWrongWords() {
    if (_isGuest) return _getLocalWordsStream('guest_wrong_words');
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('wrong_words')
        .orderBy('last_updated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WordModel.fromJson(doc.data())).toList());
  }

  Stream<Map<String, dynamic>> getUserStats() async* {
    if (_isGuest) {
      final prefs = await SharedPreferences.getInstance();
      yield* Stream.periodic(const Duration(seconds: 1), (_) {
        return {
          'streak': prefs.getInt('guest_streak') ?? 0,
          'accuracy': prefs.getInt('guest_accuracy') ?? 0,
          'total_quiz_completed': prefs.getInt('guest_total_quiz') ?? 0,
          'completed_tasks': prefs.getInt('guest_completed_tasks') ?? 0,
          'score': prefs.getInt('guest_score') ?? 0,
        };
      }).distinct();
    } else {
      yield* _firestore.collection('users').doc(_userId).snapshots().map((doc) => doc.data() as Map<String, dynamic>? ?? {});
    }
  }

  Stream<List<WordModel>> _getLocalWordsStream(String key) async* {
    final prefs = await SharedPreferences.getInstance();
    yield _parseLocalList(prefs.getStringList(key));
    yield* Stream.periodic(const Duration(seconds: 1), (_) => _parseLocalList(prefs.getStringList(key))).distinct((prev, curr) => prev.length == curr.length);
  }

  List<WordModel> _parseLocalList(List<String>? list) {
    if (list == null) return [];
    return list.map((s) => WordModel.fromJson(json.decode(s))).toList();
  }

  Future<void> checkAndResetStreak() async {
    if (_userId.isEmpty && !_isGuest) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (_isGuest) {
      final prefs = await SharedPreferences.getInstance();
      String? lastDateStr = prefs.getString('guest_last_quiz_date');
      if (lastDateStr != null) {
        DateTime lastDate = DateTime.parse(lastDateStr);
        int diff = today.difference(lastDate).inDays;
        if (lastDateStr != todayStr) await prefs.setInt('guest_completed_tasks', 0);
        if (diff > 1) await prefs.setInt('guest_streak', 0);
      }
    } else {
      final userDoc = _firestore.collection('users').doc(_userId);
      final userSnap = await userDoc.get();
      if (userSnap.exists) {
        String? lastQuizDateStr = userSnap.data()?['last_quiz_date_str'];
        if (lastQuizDateStr != null) {
          DateTime lastDate = DateTime.parse(lastQuizDateStr);
          int diff = today.difference(lastDate).inDays;
          if (diff > 1) await userDoc.update({'streak': 0});
        }
      }
    }
  }
}
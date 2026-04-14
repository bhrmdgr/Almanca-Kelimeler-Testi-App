// service/firebase/user_service.dart
import 'package:almanca_kelime_testi/features/home/home_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Çakışmayı önlemek için SharedPreferences anahtarlarına eklenecek ön ek
  final String _p = "de_";

  Future<void> updateDailyGoal(String uid, int goal, bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    if (isGuest) {
      // ✅ Misafir kullanıcı için yerel hafızaya kaydet
      await prefs.setInt('${_p}daily_goal', goal);
    } else {
      // Kayıtlı kullanıcı için hem Firestore hem yerel hafızayı güncelle
      await _firestore.collection('users').doc(uid).set(
          {'daily_goal': goal}, SetOptions(merge: true));
      await prefs.setInt('${_p}daily_goal', goal);
    }
  }

  Future<void> updateAvatar(String uid, String avatarPath, bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    if (isGuest) {
      await prefs.setString('${_p}avatarPath', avatarPath);
    } else {
      await _firestore.collection('users').doc(uid).update({
        'avatarPath': avatarPath,
      });
      // Kayıtlı kullanıcı olsa bile yerel cache'i güncelliyoruz
      await prefs.setString('${_p}avatarPath', avatarPath);
    }
  }

  Future<HomeModel?> getFirestoreUser(String uid) async {
    try {
      final now = DateTime.now();
      final dateId = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final dailyDoc = await _firestore.collection('users').doc(uid).collection('daily_series').doc(dateId).get();

      final learnedQuery = await _firestore.collection('users').doc(uid).collection('learned_words').count().get();
      final wrongQuery = await _firestore.collection('users').doc(uid).collection('wrong_words').count().get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        int learned = learnedQuery.count ?? 0;
        int wrong = wrongQuery.count ?? 0;
        int total = learned + wrong;
        int accuracy = total > 0 ? ((learned / total) * 100).toInt() : 0;

        int dailyCompleted = 0;
        if (dailyDoc.exists) {
          dailyCompleted = dailyDoc.data()?['correct_answers'] ?? 0;
        }

        return HomeModel(
          username: data['username'] ?? "Kullanıcı",
          avatarPath: data['avatarPath'],
          dailyStreak: data['streak'] ?? 0,
          accuracy: accuracy,
          totalXP: (data['score'] ?? 0).toDouble(),
          weeklyScore: (data['weekly_score'] ?? data['weeklyScore'] ?? 0).toDouble(),
          completedTasks: dailyCompleted,
          dailyGoal: data['daily_goal'] ?? 0,
          learnedWordsCount: learned,
          wrongWordsCount: wrong,
          isPremium: data['isPremium'] ?? false,
          premiumUntil: data['premiumUntil'] != null ? (data['premiumUntil'] as Timestamp).toDate() : null,
          isAutoRenew: data['isAutoRenew'] ?? true,
        );
      }
    } catch (e) {
      print("UserService getFirestoreUser Hatası: $e");
      rethrow;
    }
    return null;
  }

  Future<HomeModel> getLocalGuest() async {
    final prefs = await SharedPreferences.getInstance();
    String? expiryStr = prefs.getString('${_p}premiumUntil');

    return HomeModel(
      username: prefs.getString('${_p}guest_username') ?? "Misafir",
      avatarPath: prefs.getString('${_p}avatarPath'),
      dailyStreak: prefs.getInt('${_p}guest_streak') ?? 0,
      accuracy: prefs.getInt('${_p}guest_accuracy') ?? 0,
      totalXP: (prefs.getInt('${_p}guest_score') ?? 0).toDouble(),
      weeklyScore: (prefs.getInt('${_p}guest_score') ?? 0).toDouble(),
      completedTasks: prefs.getInt('${_p}guest_completed_tasks') ?? 0,
      dailyGoal: prefs.getInt('${_p}daily_goal') ?? 0,
      learnedWordsCount: prefs.getStringList('${_p}guest_learned_words')?.length ?? 0,
      wrongWordsCount: prefs.getStringList('${_p}guest_wrong_words')?.length ?? 0,
      isPremium: prefs.getBool('${_p}isPremium') ?? false,
      premiumUntil: expiryStr != null ? DateTime.tryParse(expiryStr) : null,
      isAutoRenew: prefs.getBool('${_p}isAutoRenew') ?? true,
    );
  }
}
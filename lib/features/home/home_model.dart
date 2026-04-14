import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class HomeModel {
  final String username;
  final int dailyStreak;
  final int accuracy;
  final double totalXP;
  final int completedTasks;
  final int dailyGoal;
  final int learnedWordsCount;
  final int wrongWordsCount;
  final String? avatarPath;
  final bool isPremium;
  final DateTime? premiumUntil; // ✅ YENİ
  final bool isAutoRenew; // ✅ YENİ
  final double weeklyScore; // ✅ YENİ

  HomeModel({
    required this.username,
    required this.dailyStreak,
    required this.accuracy,
    required this.totalXP,
    required this.completedTasks,
    required this.dailyGoal,
    required this.learnedWordsCount,
    required this.wrongWordsCount,
    required this.avatarPath,
    this.isPremium = false,
    this.premiumUntil, // ✅ Eklendi
    this.isAutoRenew = true, // ✅ Eklendi
    required this.weeklyScore, // ✅ YENİ
  });

  factory HomeModel.fromMap(Map<String, dynamic> map) {
    bool premiumValid = map['isPremium'] ?? false;
    DateTime? expiryDate;

    // ✅ Firestore'daki alan adının 'premiumUntil' olduğundan emin ol
    if (map['premiumUntil'] != null) {
      try {
        // Firestore Timestamp tipini DateTime'a çeviriyoruz
        final Timestamp expiryTimestamp = map['premiumUntil'];
        expiryDate = expiryTimestamp.toDate();

        // ✅ Süre kontrolü: Eğer tarih geçmemişse premiumValid'i zorla true yap
        if (expiryDate.isAfter(DateTime.now())) {
          premiumValid = true;
        }
      } catch (e) {
        debugPrint("HomeModel: Tarih dönüştürme hatası: $e");
      }
    }

    return HomeModel(
      username: map['username'] ?? "Öğrenci",
      dailyStreak: map['streak'] ?? 0,
      accuracy: map['accuracy'] ?? 0,
      totalXP: (map['total_xp'] ?? 0).toDouble(),
      completedTasks: map['completed_tasks'] ?? 0,
      dailyGoal: map['daily_goal'] ?? 10,
      learnedWordsCount: map['learned_count'] ?? 0,
      wrongWordsCount: map['wrong_count'] ?? 0,
      avatarPath: map['avatarPath'],
      isPremium: premiumValid,
      premiumUntil: expiryDate,
      isAutoRenew: map['isAutoRenew'] ?? true,
      weeklyScore: (map['weekly_score'] ?? 0).toDouble(), // ✅ Firestore'dan haftalık skor eklendi
    );
  }
}
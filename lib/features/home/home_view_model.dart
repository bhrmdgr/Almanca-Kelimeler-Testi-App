// features/home/home_view_model.dart
import 'package:almanca_kelime_testi/features/home/home_model.dart';
import 'package:almanca_kelime_testi/service/admob/admob_service.dart';
import 'package:almanca_kelime_testi/service/firebase/stats_service.dart';
import 'package:almanca_kelime_testi/service/firebase/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final StatsService _statsService = StatsService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ✅ Kullanıcının guest olup olmadığını bu değişken tutacak
  bool _isGuest = true;
  bool get isGuest => _isGuest;

  HomeModel? _userData;
  HomeModel? get userData => _userData;

  int? _userRank;
  int? get userRank => _userRank;

  // ✅ İNGİLİZCE'DEN AKTARILAN: Bekleyen duyuruyu tutar
  Map<String, dynamic>? _pendingAnnouncement;
  Map<String, dynamic>? get pendingAnnouncement => _pendingAnnouncement;

  Future<void> fetchUserData() async {
    if (_userData == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      await _statsService.checkAndResetStreak();

      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      // Firebase Auth durumuna göre guest durumunu sabitle
      _isGuest = (user == null || user.isAnonymous);

      await prefs.setString('user_type', _isGuest ? 'guest' : 'member');

      if (_isGuest) {
        _userData = await _userService.getLocalGuest();
      } else {
        _userData = await _userService.getFirestoreUser(user!.uid);

        if (_userData == null) {
          debugPrint("Kullanıcı dökümanı bulunamadı, oturum kapatılıyor...");
          await FirebaseAuth.instance.signOut();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (_userData != null) {
        AdMobService.isPremiumUser = _userData!.isPremium;
        if (!_isGuest) {
          await fetchUserRank(_userData!.totalXP);
        }

        // ✅ İNGİLİZCE'DEN AKTARILAN: Veriler yüklendikten sonra duyuruları kontrol et
        await checkAnnouncements();
      }

    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ İNGİLİZCE'DEN AKTARILAN: Duyuru kontrol mekanizması
  Future<void> checkAnnouncements() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('announcements').doc('current').get();

      if (doc.exists && doc.data()?['isActive'] == true) {
        final data = doc.data()!;
        final String announcementId = data['id'];

        final prefs = await SharedPreferences.getInstance();
        final String? lastReadId = prefs.getString('last_read_announcement_id');

        if (lastReadId != announcementId) {
          _pendingAnnouncement = data;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Duyuru çekme hatası: $e");
    }
  }

  // ✅ İNGİLİZCE'DEN AKTARILAN: Duyuruyu okundu olarak işaretle
  Future<void> markAnnouncementAsRead() async {
    if (_pendingAnnouncement != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_read_announcement_id', _pendingAnnouncement!['id']);
      _pendingAnnouncement = null;
      notifyListeners();
    }
  }

  Future<void> fetchUserRank(double xp) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('users')
          .where('total_xp', isGreaterThan: xp);

      final snapshot = await query.count().get();
      _userRank = (snapshot.count ?? 0) + 1;
      notifyListeners();
    } catch (e) {
      debugPrint("Sıralama çekme hatası: $e");
    }
  }

  Future<void> updateAvatar(String uid, String avatarPath, bool isGuest) async {
    try {
      await _userService.updateAvatar(uid, avatarPath, isGuest);
      await fetchUserData();
    } catch (e) {
      debugPrint("Avatar güncelleme hatası: $e");
    }
  }

  Future<void> setDailyGoal(int goal) async {
    final user = FirebaseAuth.instance.currentUser;
    String uid = user?.uid ?? 'guest_user';

    try {
      await _userService.updateDailyGoal(uid, goal, _isGuest);
      await fetchUserData();
    } catch (e) {
      debugPrint("Hedef güncelleme hatası: $e");
    }
  }
}
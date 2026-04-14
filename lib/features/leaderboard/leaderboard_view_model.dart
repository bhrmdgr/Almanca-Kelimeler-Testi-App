import 'package:almanca_kelime_testi/service/firebase/leaderboard_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardViewModel extends ChangeNotifier {
  final LeaderboardService _service = LeaderboardService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // --- GENEL SIRALAMA VERİLERİ ---
  List<DocumentSnapshot> _topPlayers = [];
  List<DocumentSnapshot> get topPlayers => _topPlayers;

  List<DocumentSnapshot> _aboveMe = [];
  List<DocumentSnapshot> get aboveMe => _aboveMe;

  List<DocumentSnapshot> _belowMe = [];
  List<DocumentSnapshot> get belowMe => _belowMe;

  int? _myRank;
  int? get myRank => _myRank;

  // --- HAFTALIK SIRALAMA VERİLERİ ---
  List<DocumentSnapshot> _topWeeklyPlayers = [];
  List<DocumentSnapshot> get topWeeklyPlayers => _topWeeklyPlayers;

  List<DocumentSnapshot> _aboveMeWeekly = [];
  List<DocumentSnapshot> get aboveMeWeekly => _aboveMeWeekly;

  List<DocumentSnapshot> _belowMeWeekly = [];
  List<DocumentSnapshot> get belowMeWeekly => _belowMeWeekly;

  int? _myWeeklyRank;
  int? get myWeeklyRank => _myWeeklyRank;

  // ✅ İNGİLİZCE'DEN AKTARILAN: GEÇEN HAFTANIN ŞAMPİYONLARI VERİSİ
  List<Map<String, dynamic>> _lastWeekChampions = [];
  List<Map<String, dynamic>> get lastWeekChampions => _lastWeekChampions;

  // ✅ Verileri çeken ana metod
  Future<void> fetchLeaderboardData(double totalXP, double weeklyXP) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Verileri Paralel Olarak Çek (Service'e eklediğimiz yeni metodu da dahil ettik)
      final results = await Future.wait([
        // Genel Sıralama İşlemleri
        _service.getUserRank(totalXP, isWeekly: false),
        _service.getNeighboringLeaderboard(totalXP.toInt(), isWeekly: false),

        // Haftalık Sıralama İşlemleri
        _service.getUserRank(weeklyXP, isWeekly: true),
        _service.getNeighboringLeaderboard(weeklyXP.toInt(), isWeekly: true),

        // ✅ Geçen Haftanın Şampiyonlarını Çek (Listede 4. indekse düşer)
        _service.getLastWeekChampions(),
      ]);

      // Genel Sonuçlar
      _myRank = results[0] as int;
      final generalData = results[1] as Map<String, List<DocumentSnapshot>>;
      _topPlayers = generalData['topOne'] ?? [];
      _aboveMe = generalData['above'] ?? [];
      _belowMe = generalData['below'] ?? [];

      // Haftalık Sonuçlar
      _myWeeklyRank = results[2] as int;
      final weeklyData = results[3] as Map<String, List<DocumentSnapshot>>;
      _topWeeklyPlayers = weeklyData['topOne'] ?? [];
      _aboveMeWeekly = weeklyData['above'] ?? [];
      _belowMeWeekly = weeklyData['below'] ?? [];

      // ✅ Şampiyonları Ata (İngilizce versiyonundaki gibi)
      _lastWeekChampions = results[4] as List<Map<String, dynamic>>;

    } catch (e) {
      debugPrint("Leaderboard ViewModel Hatası: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
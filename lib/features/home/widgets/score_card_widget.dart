import 'dart:ui';
import 'package:almanca_kelime_testi/features/home/home_model.dart';
import 'package:almanca_kelime_testi/features/home/home_view_model.dart';
import 'package:almanca_kelime_testi/features/home/widgets/rank_journey_view.dart';
import 'package:almanca_kelime_testi/helpers/rank_manager/rank_manager.dart';
import 'package:almanca_kelime_testi/helpers/routers/routers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScoreCardWidget extends StatelessWidget {
  final HomeModel userData;
  final VoidCallback onShowLeaderboard;

  const ScoreCardWidget({
    super.key,
    required this.userData,
    required this.onShowLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ KRİTİK: TÜM SAYFA BOYUNCA KULLANILACAK RANK BİLGİSİ SADECE TOTAL XP'DEN GELİYOR
    final int totalXP = userData.totalXP.toInt();
    final allRanks = RankManager.getAllRanks();

    int currentIndex = 0;
    for (int i = 0; i < allRanks.length; i++) {
      if (totalXP >= allRanks[i]['min']) currentIndex = i;
    }

    final currentRank = allRanks[currentIndex]; // ✅ Bu artık sabit rütbemiz
    final Color rankColor = currentRank['color'];
    final int nextGoal = (currentIndex + 1 < allRanks.length) ? allRanks[currentIndex + 1]['min'] : 55000;
    final double progress = (totalXP / nextGoal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rankColor.withOpacity(0.9),
            rankColor.withBlue(200).withOpacity(1.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1))),
            ),

            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                children: [
                  // --- 1. KATMAN: RÜTBE SERÜVENİ (TIMELINE) ---
                  GestureDetector(
                    onTap: () => _showRankJourney(context, totalXP),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimelineNode(
                          currentIndex > 0 ? allRanks[currentIndex - 1]['icon'] : "🚀",
                          currentIndex > 0 ? "TAMAMLANDI" : "BAŞLANGIÇ",
                          isPassed: currentIndex > 0,
                          isStart: currentIndex == 0,
                        ),

                        // MEVCUT RANK
                        _buildMainRankNode(currentRank, progress),

                        _buildTimelineNode(
                          currentIndex + 1 < allRanks.length ? allRanks[currentIndex + 1]['icon'] : "🏆",
                          "${nextGoal - totalXP} XP KALDI",
                          isLocked: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- 2. KATMAN: İSTATİSTİK PANELİ ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox("HAFTALIK", "${userData.weeklyScore.toInt()}", Icons.bolt_rounded, Colors.cyanAccent),
                        _buildVerticalDivider(),
                        _buildStatBox("TOPLAM", "${totalXP}", Icons.emoji_events_rounded, Colors.amberAccent),
                        _buildVerticalDivider(),
                        _buildStatBox("SERİ", "${userData.dailyStreak}", Icons.whatshot_rounded, Colors.orangeAccent),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 3. KATMAN: ARENA ERİŞİMİ ---
                  _buildArenaButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode(String icon, String label, {bool isLocked = false, bool isPassed = false, bool isStart = false}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: (isPassed || isStart) ? Colors.white24 : Colors.black26,
                shape: BoxShape.circle,
                border: Border.all(color: (isPassed || isStart) ? Colors.white38 : Colors.white10),
              ),
              child: Center(
                child: Opacity(
                  opacity: isLocked ? 0.3 : 0.8,
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
            if (isLocked) const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
            if (isPassed)
              const Positioned(
                right: 0, bottom: 0,
                child: CircleAvatar(radius: 8, backgroundColor: Colors.greenAccent, child: Icon(Icons.check, size: 10, color: Colors.black)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: (isLocked) ? Colors.white54 : Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMainRankNode(Map<String, dynamic> rank, double progress) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 85, width: 85,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Container(
              height: 65, width: 65,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Center(child: Text(rank['icon'], style: const TextStyle(fontSize: 38))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(rank['title'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerticalDivider() => Container(height: 30, width: 1, color: Colors.white10);

  Widget _buildArenaButton(BuildContext context) {
    // ✅ ViewModel'i dinliyoruz
    final viewModel = context.watch<HomeViewModel>();

    // ✅ HomeViewModel'de fetchUserData içinde sabitlediğimiz değişkeni kullanıyoruz
    final bool isGuest = viewModel.isGuest;
    final userRank = viewModel.userRank;

    return InkWell(
      onTap: () {
        // ✅ GİRİŞ KONTROLÜ: ViewModel'deki hazır veriye göre karar veriyoruz
        if (isGuest) {
          debugPrint("Sistem: Misafir girişi engellendi.");
          _showGuestWarning(context);
        } else {
          Navigator.pushNamed(context, AppRouters.leaderboard, arguments: userData);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard_rounded, color: Colors.amberAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "ARENA LİGİ",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Text(
                        isGuest ? "KAYIT OL VE YARIŞ" : "Genel ve Haftalık\nSıralamanı Gör",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),

            // ✅ Sağdaki kilit ikonu veya sıralama kontrolü
            if (isGuest)
              const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 20)
            else if (userRank != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: userRank <= 3
                        ? [Colors.amber, Colors.orangeAccent]
                        : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "#$userRank",
                  style: TextStyle(
                    color: userRank <= 3 ? Colors.black : Colors.blueGrey.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  void _showGuestWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Arena'ya Katıl", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Dünya sıralamasında yer almak ve diğer dil öğrencileriyle yarışmak için bir hesap oluşturmalısın.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("KAPAT", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRankJourney(BuildContext context, int xp) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => FractionallySizedBox(heightFactor: 0.85, child: RankJourneyView(userXP: xp)));
  }

  void _showPremiumAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Arena'ya Giriş", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Dünya sıralamasında yerini al ve diğerleriyle yarış!", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, AppRouters.premium); },
            child: const Text("PREMIUM AL"),
          ),
        ],
      ),
    );
  }
}
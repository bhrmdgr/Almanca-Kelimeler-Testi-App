import 'package:almanca_kelime_testi/helpers/rank_manager/rank_manager.dart';
import 'package:flutter/material.dart';

class RankJourneyView extends StatelessWidget {
  final int userXP;
  const RankJourneyView({super.key, required this.userXP});

  @override
  Widget build(BuildContext context) {
    final allRanks = RankManager.getAllRanks();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F36), // Koyu premium tema
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.all(25.0),
            child: Text(
              "RÜTBE YOLCULUĞU",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              physics: const BouncingScrollPhysics(),
              itemCount: allRanks.length,
              itemBuilder: (context, index) {
                final rank = allRanks[index];
                final bool isUnlocked = userXP >= rank['min'];
                final bool isLast = index == allRanks.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      // Sol Taraf: Çizgi ve İkon
                      Column(
                        children: [
                          _buildRankIcon(rank, isUnlocked),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isUnlocked ? rank['color'] : Colors.white10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Sağ Taraf: Detaylar
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: _buildRankContent(rank, isUnlocked),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankIcon(Map<String, dynamic> rank, bool isUnlocked) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isUnlocked ? rank['color'].withOpacity(0.15) : Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: isUnlocked ? rank['color'] : Colors.white10, width: 2),
      ),
      child: Center(
        // TextStyle içindeki opacity kaldırıldı,
        // yerine tüm Text widget'ı Opacity widget'ı ile sarmalandı.
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.2,
          child: Text(
            rank['icon'],
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildRankContent(Map<String, dynamic> rank, bool isUnlocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rank['title'],
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isUnlocked)
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18)
            else
              Text(
                "${rank['min']} XP",
                style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          rank['desc'],
          style: TextStyle(color: isUnlocked ? Colors.white60 : Colors.white10, fontSize: 13),
        ),
      ],
    );
  }
}
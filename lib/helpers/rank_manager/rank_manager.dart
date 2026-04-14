import 'package:flutter/material.dart';

class RankManager {
  static List<Map<String, dynamic>> getAllRanks() {
    return [
      {
        'title': 'Yolcu',
        'icon': '👟',
        'color': const Color(0xFF9E9E9E),
        'min': 0,
        'desc': 'Kelimelerin dünyasına ilk adımını attın!'
      },
      {
        'title': 'Çırak',
        'icon': '📖',
        'color': const Color(0xFF4CAF50),
        'min': 150, // 500'den 150'ye çektik (Yaklaşık 1-2 testte atlar)
        'desc': 'Temel kelimeleri kavramaya başladın.'
      },
      {
        'title': 'Kaşif',
        'icon': '🧭',
        'color': const Color(0xFF2196F3),
        'min': 600, // 1500'den 600'e çektik (Hızlı bir başarı hissi)
        'desc': 'Yeni dil ufuklarını keşfediyorsun.'
      },
      {
        'title': 'Konuşmacı',
        'icon': '🗣️',
        'color': const Color(0xFF9C27B0),
        'min': 2000, // 4000'den 2000'e çektik
        'desc': 'Kendini ifade etmeye hazırsın!'
      },
      {
        'title': 'Bursiyer',
        'icon': '🎓',
        'color': const Color(0xFFFF9800),
        'min': 5000, // 8000'den 5000'e çektik
        'desc': 'Dil bilgisinde akademik bir derinlik.'
      },
      {
        'title': 'Usta',
        'icon': '⚔️',
        'color': const Color(0xFFE91E63),
        'min': 12000, // Buradan itibaren zorlaşıyor
        'desc': 'Kelimeler senin en güçlü silahın.'
      },
      {
        'title': 'Bilge',
        'icon': '🧙',
        'color': const Color(0xFF3F51B5),
        'min': 25000,
        'desc': 'Dilin tüm sırlarına hakimsin.'
      },
      {
        'title': 'Efsane',
        'icon': '👑',
        'color': const Color(0xFFFFD700),
        'min': 45000, // Efsane olmak gerçekten emek istesin
        'desc': 'Sen artık bir dil efsanesisin!'
      },
    ];
  }

  static Map<String, dynamic> getRank(int score) {
    final ranks = getAllRanks();

    for (int i = ranks.length - 1; i >= 0; i--) {
      if (score >= ranks[i]['min']) {
        // Dinamik bir "maksimum hedef" için son rütbenin 1.5 katını baz alabiliriz
        int nextXP = (i + 1 < ranks.length) ? ranks[i + 1]['min'] : (ranks[i]['min'] * 1.5).toInt();

        return {
          ...ranks[i],
          'next': nextXP,
        };
      }
    }
    return ranks[0];
  }
}
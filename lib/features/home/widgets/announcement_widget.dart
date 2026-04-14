import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:almanca_kelime_testi/features/home/home_view_model.dart';

class AnnouncementWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const AnnouncementWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.indigoAccent.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- ÜST KISIM: CANLI GRADYAN VE İKON ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                            ),
                            child: const Icon(Icons.notifications_active_rounded,
                                size: 30, color: Color(0xFF6366F1)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "ÖNEMLİ DUYURU",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // --- BAŞLIK ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      data['title'] ?? "Duyuru",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5
                      ),
                    ),
                  ),

                  // --- MESAJ ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    child: Text(
                      data['message'] ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // --- ALT KISIM: BUTON ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          context.read<HomeViewModel>().markAnnouncementAsRead();
                        },
                        child: const Text(
                          "HARİKA, ANLADIM!",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize: 13
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- YENİ EKLENEN DESTEK NOTU ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Destek, şikayet ve önerileriniz için Ayarlar -> Bize Ulaşın bölümünden bize ulaşabilirsiniz.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: const Color(0xFF1E293B).withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
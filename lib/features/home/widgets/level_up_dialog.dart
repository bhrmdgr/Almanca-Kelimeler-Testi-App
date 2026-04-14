import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // ✅ Ses için eklendi

class LevelUpDialog extends StatefulWidget {
  final Map<String, dynamic> rank;
  const LevelUpDialog({super.key, required this.rank});

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> {
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer(); // ✅ Ses oynatıcı tanımlandı

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    // ✅ Diyalog açılır açılmaz hem konfeti hem ses başlasın
    _confettiController.play();
    _playLevelUpSound();
  }

  // ✅ Ses çalma fonksiyonu
  Future<void> _playLevelUpSound() async {
    try {
      // assets/sounds/congrats.mp3 dosyasını çalar
      await _audioPlayer.play(AssetSource('sounds/congrats.mp3'));
    } catch (e) {
      debugPrint("Seviye atlama sesi çalınamadı: $e");
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose(); // ✅ Bellek sızıntısını önlemek için dispose ediyoruz
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // BİLGİ KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🎉 TEBRİKLER!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 10),
                const Text("YENİ RÜTBE KAZANDIN",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (widget.rank['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(widget.rank['icon'] ?? "🏆", style: const TextStyle(fontSize: 60)),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.rank['title']?.toUpperCase() ?? "",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: widget.rank['color']),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Dil yolculuğunda büyük bir adım attın. Harika gidiyorsun!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.rank['color'],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("DEVAM ET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // KONFETİLER
          IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green, Colors.blue, Colors.pink,
                Colors.orange, Colors.purple, Colors.yellow, Colors.red
              ],
              numberOfParticles: 60,
              gravity: 0.1,
              maxBlastForce: 25,
              minBlastForce: 10,
              createParticlePath: drawStar,
            ),
          ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (math.pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = size.width / 2;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(-90);
    path.moveTo(size.width / 2, 0);
    for (int step = 0; step < numberOfPoints; step++) {
      path.lineTo(
          halfWidth + externalRadius * math.cos(step * degreesPerStep + fullAngle),
          halfWidth + externalRadius * math.sin(step * degreesPerStep + fullAngle));
      path.lineTo(
          halfWidth + internalRadius * math.cos(step * degreesPerStep + halfDegreesPerStep + fullAngle),
          halfWidth + internalRadius * math.sin(step * degreesPerStep + halfDegreesPerStep + fullAngle));
    }
    path.close();
    return path;
  }
}
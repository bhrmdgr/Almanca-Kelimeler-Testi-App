import 'package:almanca_kelime_testi/features/quiz/quiz_model.dart';
import 'package:almanca_kelime_testi/helpers/routers/routers.dart';
import 'package:almanca_kelime_testi/service/firebase/stats_service.dart';
import 'package:flutter/material.dart';


class WrongWordsView extends StatefulWidget {
  const WrongWordsView({super.key});

  @override
  State<WrongWordsView> createState() => _WrongWordsViewState();
}

class _WrongWordsViewState extends State<WrongWordsView> {
  int _selectedWrongRepeatCount = 10;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // ✅ Düzeltildi: Sadece geri döner
        ),
        title: const Text("Hata Defterim",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<WordModel>>(
        stream: StatsService().getWrongWords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final wrongWords = snapshot.data ?? [];

          if (wrongWords.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildRepeatButton(context, wrongWords),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: wrongWords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildWrongWordCard(wrongWords[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text("Harika! Hiç yanlışın yok.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }


  Widget _buildRepeatButton(BuildContext context, List<WordModel> words) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final List<WordModel> fullList = List.from(words)..shuffle();
                  Navigator.pushNamed(
                    context,
                    AppRouters.quizView,
                    arguments: {
                      'quizList': fullList.take(_selectedWrongRepeatCount).toList(),
                      'isReviewMode': true,
                    },
                  );
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text("YANLIŞLARI ÇÖZ",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF416C).withOpacity(0.5)),
              ),
              child: PopupMenuButton<int>(
                initialValue: _selectedWrongRepeatCount,
                onSelected: (int value) => setState(() => _selectedWrongRepeatCount = value),
                itemBuilder: (context) => [5, 10, 15, 20].map((int count) {
                  return PopupMenuItem<int>(
                    value: count,
                    child: Text("$count Soru"),
                  );
                }).toList(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("$_selectedWrongRepeatCount",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF416C), fontSize: 18)),
                    const Text("SORU", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongWordCard(WordModel word) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.de, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(word.tr, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(word.level, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Text(word.type, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}
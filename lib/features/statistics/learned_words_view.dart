import 'package:almanca_kelime_testi/features/quiz/quiz_model.dart';
import 'package:almanca_kelime_testi/helpers/routers/routers.dart';
import 'package:almanca_kelime_testi/service/firebase/stats_service.dart';
import 'package:flutter/material.dart';


class LearnedWordsView extends StatefulWidget {
  const LearnedWordsView({super.key});

  @override
  State<LearnedWordsView> createState() => _LearnedWordsViewState();
}

class _LearnedWordsViewState extends State<LearnedWordsView> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // ✅ ÇÖZÜM: Stream'i bir değişkene atıyoruz
  late Stream<List<WordModel>> _learnedWordsStream;

  int _selectedRepeatCount = 10;

  @override
  void initState() {
    super.initState();
    // ✅ Stream'i burada başlatıyoruz ki setState olunca sıfırlanmasın
    _learnedWordsStream = StatsService().getLearnedWords().asBroadcastStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<List<WordModel>>(
          stream: _learnedWordsStream, // ✅ Sabit stream kullanılıyor
          builder: (context, snapshot) {
            int count = snapshot.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Öğrendiklerim",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
                Text("$count kelime",
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF2ECC71)),
            ),
          )
        ],
      ),
      body: StreamBuilder<List<WordModel>>(
        stream: _learnedWordsStream, // ✅ Sabit stream kullanılıyor
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allWords = snapshot.data ?? [];

          // Filtreleme işlemi
          final filteredWords = allWords.where((word) {
            final query = searchQuery.toLowerCase();
            return word.de.toLowerCase().contains(query) ||
                word.tr.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              _buildSearchField(),
              if (allWords.isNotEmpty) _buildRepeatLearnedButton(context, allWords),
              Expanded(
                child: allWords.isEmpty
                    ? const Center(child: Text("Henüz kelime öğrenilmemiş."))
                    : filteredWords.isEmpty
                    ? const Center(child: Text("Sonuç bulunamadı."))
                    : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredWords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildWordCard(filteredWords[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          // Artık sadece searchQuery değişecek, StreamBuilder baştan kurulmayacak
          setState(() {
            searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: "Kelime ara...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => searchQuery = "");
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ... _buildRepeatLearnedButton ve _buildWordCard aynı kalabilir ...

  Widget _buildRepeatLearnedButton(BuildContext context, List<WordModel> words) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          // Ana Buton
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF2ECC71), Color(0xFF27AE60)]),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final List<WordModel> quizList = List.from(words)..shuffle();
                  Navigator.pushNamed(
                    context,
                    AppRouters.quizView,
                    arguments: {
                      'quizList': quizList.take(_selectedRepeatCount).toList(), // Seçilen sayı kadar al
                      'isReviewMode': false,
                      'isLearnedReview': true,
                    },
                  );
                },
                icon: const Icon(Icons.psychology_rounded, color: Colors.white),
                label: const Text("TEKRAR ET",
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
          // Soru Sayısı Seçicisi
          Expanded(
            flex: 1,
            child: Container(
              height: 58, // Buton yüksekliği ile uyumlu
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.5)),
              ),
              child: PopupMenuButton<int>(
                initialValue: _selectedRepeatCount,
                onSelected: (int value) => setState(() => _selectedRepeatCount = value),
                itemBuilder: (context) => [10, 20, 30, 50].map((int count) {
                  return PopupMenuItem<int>(
                    value: count,
                    child: Text("$count Soru"),
                  );
                }).toList(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("$_selectedRepeatCount",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF27AE60), fontSize: 18)),
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

  Widget _buildWordCard(WordModel word) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.de, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(word.tr, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(word.level,
                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Text(word.type, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}
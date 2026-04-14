import 'package:almanca_kelime_testi/features/quiz/quiz_view_model.dart';
import 'package:almanca_kelime_testi/helpers/routers/routers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuizOptionsView extends StatefulWidget {
  const QuizOptionsView({super.key});

  @override
  State<QuizOptionsView> createState() => _QuizOptionsViewState();
}

class _QuizOptionsViewState extends State<QuizOptionsView> {
  // ✅ ViewModel ve JSON anahtarlarıyla uyumlu Türkçe karşılıklar
  final Map<String, String> _typeTurkishLabels = {
    'all': 'Hepsi',
    'noun': 'İsim',
    'verb': 'Fiil',
    'adjective': 'Sıfat',
    'adverb': 'Zarf',
  };

  // ✅ Üstte görünecek teknik Almanca terimler
  final Map<String, String> _typeGermanLabels = {
    'all': 'ALLE',
    'noun': 'NOMEN',
    'verb': 'VERBEN',
    'adjective': 'ADJEKTIVE',
    'adverb': 'ADVERBIEN',
  };

  final Map<String, String> _levelXpMultipliers = {
    'A1': '10 XP',
    'A2': '10 XP',
    'B1': '15 XP',
    'B2': '15 XP',
    'C1': '20 XP',
    'C2': '20 XP',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<QuizViewModel>().fetchWords());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuizViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Quiz Özelleştirme",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0E7FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
            : SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // 1. KATEGORİ SEÇİMİ (Yatay Liste)
                  _sectionLabel("Kelime Kategorisi", Icons.grid_view_rounded),
                  const SizedBox(height: 15),
                  _buildHorizontalTypePicker(vm),

                  const SizedBox(height: 25),

                  // 2. SORU YÖNÜ SEÇİMİ (DE/TR)
                  _buildOptionCard(
                    title: "Soru Yönü",
                    icon: Icons.swap_horiz_rounded,
                    color: Colors.purpleAccent,
                    child: _buildQuestionModePicker(vm),
                  ),

                  const SizedBox(height: 20),

                  // 3. ZORLUK SEVİYESİ (Grid)
                  _buildOptionCard(
                    title: "Zorluk Seviyesi",
                    icon: Icons.bolt_rounded,
                    color: Colors.orangeAccent,
                    child: _buildLevelGrid(vm),
                  ),

                  const SizedBox(height: 20),

                  // 4. SORU SAYISI
                  _buildOptionCard(
                    title: "Soru Sayısı",
                    icon: Icons.ads_click_rounded,
                    color: Colors.blueAccent,
                    child: _buildEqualQuestionCountPicker(vm),
                  ),

                  const SizedBox(height: 40),
                  _buildStartButton(vm),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hazır mısın? 🚀",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.indigo.shade900)),
        const SizedBox(height: 4),
        Text("Almanca kelime dünyasını keşfetmeye başla.",
            style: TextStyle(color: Colors.indigo.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.indigo.shade700),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.indigo.shade800)),
      ],
    );
  }

  Widget _buildQuestionModePicker(QuizViewModel vm) {
    return Row(
      children: [
        _modeItem(vm, QuizQuestionMode.deToTr, "DE ➔ TR"),
        _modeItem(vm, QuizQuestionMode.trToDe, "TR ➔ DE"),
        _modeItem(vm, QuizQuestionMode.random, "KARIŞIK"),
      ],
    );
  }

  Widget _modeItem(QuizViewModel vm, QuizQuestionMode mode, String label) {
    bool isSelected = vm.selectedQuestionMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setQuestionMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.purpleAccent : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white : Colors.blueGrey,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalTypePicker(QuizViewModel vm) {
    return SizedBox(
      height: 75,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: vm.types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = vm.types[index];
          final isSelected = vm.selectedType == type;

          // ✅ UI maskeleme Map'leri üzerinden yapılıyor
          final turkishLabel = _typeTurkishLabels[type] ?? "";
          final germanLabel = _typeGermanLabels[type] ?? type.toUpperCase();

          return GestureDetector(
            onTap: () => vm.setType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                border: Border.all(color: isSelected ? Colors.transparent : Colors.white),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    germanLabel, // ✅ Üstte Almanca: NOMEN, VERBEN vb.
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.indigo.shade400,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    turkishLabel, // ✅ Altta Türkçe: İsim, Fiil vb.
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.indigo.shade200,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelGrid(QuizViewModel vm) {
    final List<String> levels = ['A1','B1','C1', 'A2', 'B2', 'C2'];
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final isSelected = vm.selectedLevel == level;
        final xpLabel = _levelXpMultipliers[level] ?? "";

        return GestureDetector(
          onTap: () => vm.setLevel(level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orangeAccent.shade700 : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(15),
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Soru başı $xpLabel",
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEqualQuestionCountPicker(QuizViewModel vm) {
    return Row(
      children: vm.questionCounts.map((count) {
        bool isSelected = vm.selectedQuestionCount == count;
        return Expanded(
          child: GestureDetector(
            onTap: () => vm.setQuestionCount(count),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStartButton(QuizViewModel vm) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFC026D3)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: () {
          final quizList = vm.generateQuizList();

          if (quizList.isEmpty) {
            _showError("Bu kriterlere uygun Almanca kelime bulamadık.");
          } else {
            Navigator.pushNamed(
              context,
              AppRouters.quizView,
              arguments: {
                'quizList': quizList,
                'isReviewMode': false,
              },
            );
          }
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("BAŞLAT", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(20),
    ),
  );
}
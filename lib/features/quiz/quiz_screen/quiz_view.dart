import 'package:almanca_kelime_testi/features/admob_widget/smart_banner_widget.dart';
import 'package:almanca_kelime_testi/features/quiz/quiz_model.dart';
import 'package:almanca_kelime_testi/features/quiz/quiz_view_model.dart';
import 'package:almanca_kelime_testi/service/admob/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class QuizView extends StatefulWidget {
  final List<WordModel> quizList;
  final bool isReviewMode;
  final bool isLearnedReview;

  const QuizView({
    super.key,
    required this.quizList,
    this.isReviewMode = false,
    this.isLearnedReview = false,
  });
  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  String? selectedOption;
  bool isChecking = false;
  bool showScorePop = false;

  final AudioPlayer audioPlayer = AudioPlayer();
  final AudioPlayer effectPlayer = AudioPlayer();
  bool _isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    AdMobService.loadInterstitialAd();
  }

  Future<void> _initializeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<QuizViewModel>();
      vm.resetQuiz();
      if (widget.quizList.isNotEmpty) {
        await vm.generateOptions(widget.quizList[0]);
        // ✅ İngilizce projesindeki otomatik seslendirme mantığı (DeToTr kontrolüyle)
        if (vm.isCurrentQuestionDeToTr) {
          _speak(widget.quizList[0].de, isGerman: true);
        }
      }
    });
  }

  Future<void> _speak(String text, {required bool isGerman}) async {
    if (_isSoundEnabled && text.isNotEmpty) {
      try {
        String langCode = isGerman ? "de" : "tr";
        String url = "https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(text)}&tl=$langCode&client=tw-ob";
        await audioPlayer.play(UrlSource(url));
      } catch (e) {
        debugPrint("Ses çalma hatası: $e");
      }
    }
  }

  Future<void> _playResultSound(bool isCorrect) async {
    if (_isSoundEnabled) {
      try {
        await effectPlayer.stop();
        String path = isCorrect ? "sounds/correct.mp3" : "sounds/wrong.mp3";
        await effectPlayer.play(AssetSource(path), volume: 0.8);
      } catch (e) {
        debugPrint("Efekt sesi hatası: $e");
      }
    }
  }

  Future<bool> _showBackDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Testi Bırak?", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1F36))),
        content: const Text(
          "Test bitmeden çıkarsanız sonuçlarınız kaydedilmeyecektir. Yine de çıkmak istiyor musunuz?",
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("GERİ DÖN", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YİNE DE ÇIK", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    effectPlayer.dispose();
    super.dispose();
  }

  Color _getBorderColor(String option, WordModel word, bool isDeToTr) {
    String correctVal = isDeToTr ? word.tr : word.de;
    if (selectedOption == null) return Colors.black.withOpacity(0.05);
    if (option == correctVal) return Colors.greenAccent.shade700;
    if (option == selectedOption && option != correctVal) return Colors.redAccent.shade400;
    return Colors.black.withOpacity(0.05);
  }

  Color _getFillColor(String option, WordModel word, bool isDeToTr) {
    String correctVal = isDeToTr ? word.tr : word.de;
    if (selectedOption == null) return Colors.white;
    if (option == correctVal) return Colors.green.shade50;
    if (option == selectedOption && option != correctVal) return Colors.red.shade50;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuizViewModel>();
    if (vm.currentQuestionIndex >= widget.quizList.length) return const Scaffold();

    final currentWord = widget.quizList[vm.currentQuestionIndex];
    final double progress = (vm.currentQuestionIndex + 1) / widget.quizList.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _showBackDialog();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1F36), size: 28),
            onPressed: () async {
              final bool shouldPop = await _showBackDialog();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
          title: _buildProgressBar(progress, vm.currentQuestionIndex + 1, widget.quizList.length),
          actions: [
            IconButton(
              icon: Icon(
                _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _isSoundEnabled ? const Color(0xFF6366F1) : Colors.grey,
              ),
              onPressed: () => setState(() => _isSoundEnabled = !_isSoundEnabled),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildScoreBoard(vm),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildWordCard(currentWord, vm.isCurrentQuestionDeToTr),
                      const SizedBox(height: 32),
                      ...vm.currentOptions.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAnimatedOption(vm, option, currentWord),
                      )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: !widget.isReviewMode && !widget.isLearnedReview
            ? Container(
          color: Colors.white, // Alt barın arka plan rengi
          child: SafeArea(
            // ✅ iOS'ta (Home Indicator) boşluk bırakmaz, direkt yaslar.
            // ✅ Android'de navigasyon butonları için gerekli boşluğu bırakır.
            bottom: Theme.of(context).platform == TargetPlatform.android,
            top: false,
            child: SmartBannerWidget(adUnitId: AdMobService.bannerAdUnitIdQuiz),
          ),
        )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildProgressBar(double progress, int current, int total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$current", style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900, fontSize: 14)),
            Text(" / $total", style: TextStyle(color: Colors.indigo.withOpacity(0.3), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: 120,
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 120 * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(WordModel word, bool isDeToTr) {
    String questionText = isDeToTr ? word.de : word.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _speak(questionText, isGerman: isDeToTr),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0F3FF), shape: BoxShape.circle),
              child: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1), size: 30),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            questionText.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1A1F36), letterSpacing: -1),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedOption(QuizViewModel vm, String option, WordModel correctWord) {
    Color borderColor = _getBorderColor(option, correctWord, vm.isCurrentQuestionDeToTr);
    Color fillColor = _getFillColor(option, correctWord, vm.isCurrentQuestionDeToTr);
    String correctVal = vm.isCurrentQuestionDeToTr ? correctWord.tr : correctWord.de;
    bool isSelected = selectedOption == option;
    bool isCorrect = option == correctVal;

    return GestureDetector(
      onTap: isChecking ? null : () => _handleAnswer(vm, option, correctWord),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isChecking ? borderColor : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected || (isChecking && isCorrect) ? const Color(0xFF1A1F36) : const Color(0xFF5A6275),
                ),
              ),
            ),
            if (isChecking && isCorrect) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
            if (isSelected && !isCorrect) const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 24),
          ],
        ),
      ),
    );
  }

  void _handleAnswer(QuizViewModel vm, String option, WordModel word) async {
    if (isChecking) return;
    setState(() { selectedOption = option; isChecking = true; showScorePop = true; });

    String correctVal = vm.isCurrentQuestionDeToTr ? word.tr : word.de;
    bool isCorrect = (option == correctVal);
    _playResultSound(isCorrect);

    vm.answerQuestion(word, option, isReviewMode: widget.isReviewMode, isLearnedReview: widget.isLearnedReview);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => showScorePop = false);
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      if (vm.currentQuestionIndex < widget.quizList.length - 1) {
        await vm.nextQuestion(widget.quizList);
        setState(() { selectedOption = null; isChecking = false; });
        final nextWord = widget.quizList[vm.currentQuestionIndex];

        // ✅ Yeni soruda sadece Almanca ise otomatik seslendir
        if (vm.isCurrentQuestionDeToTr) {
          _speak(nextWord.de, isGerman: true);
        }
      } else {
        await vm.uploadResults(widget.quizList.length);
        if (mounted) {
          // ✅ Reklam gösterme kontrolü senkronize edildi
          bool canShowAd = !widget.isReviewMode && !widget.isLearnedReview && vm.shouldShowInterstitialAd(widget.quizList.length);
          if (canShowAd) {
            AdMobService.showInterstitialAd();
          }
          _showResultDialog(vm);
        }
      }
    }
  }

  Widget _buildScoreBoard(QuizViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _scoreBadge(vm.correctCount.toString(), Colors.green, Icons.check_circle_rounded),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                  Text("${vm.currentScore} XP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            if (showScorePop)
              Positioned(
                top: -30,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: -20),
                  duration: const Duration(milliseconds: 500),
                  builder: (_, double val, __) => Transform.translate(
                    offset: Offset(0, val),
                    child: Text(vm.lastEarnedPoints > 0 ? "+${vm.lastEarnedPoints}" : "${vm.lastEarnedPoints}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                            color: vm.lastEarnedPoints > 0 ? Colors.green : Colors.redAccent)),
                  ),
                ),
              ),
          ],
        ),
        _scoreBadge(vm.wrongCount.toString(), Colors.redAccent, Icons.cancel_rounded),
      ],
    );
  }

  Widget _scoreBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _showResultDialog(QuizViewModel vm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 70),
              const SizedBox(height: 16),
              const Text("HARİKA İŞ!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              Text("${vm.currentScore} XP KAZANDIN", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _resDetail(vm.correctCount, "Doğru", Colors.green),
                  _resDetail(vm.wrongCount, "Yanlış", Colors.redAccent),
                ],
              ),
              const SizedBox(height: 32),
              if (!widget.isReviewMode && !widget.isLearnedReview)
                _dialogBtn("YENİ TEST", const Color(0xFF2ECC71), () { Navigator.pop(context); _startNewQuiz(); }),
              if (vm.wrongWords.isNotEmpty)
                _dialogBtn("YANLIŞLARI TEKRAR ET", Colors.redAccent, () {
                  List<WordModel> retryList = List.from(vm.wrongWords);
                  Navigator.pop(context);
                  _startRetryQuiz(retryList);
                }),
              _dialogBtn("ANA SAYFA", const Color(0xFF6366F1), () { Navigator.pop(context); Navigator.pop(context); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resDetail(int val, String label, Color color) {
    return Column(children: [
      Text("$val", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black38, fontSize: 12)),
    ]);
  }

  Widget _dialogBtn(String label, Color color, VoidCallback onTap, {Color txtColor = Colors.white}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label, style: TextStyle(color: txtColor, fontWeight: FontWeight.w900)),
      ),
    );
  }

  void _startNewQuiz() {
    final vm = context.read<QuizViewModel>();
    AdMobService.loadInterstitialAd();
    List<WordModel> newList = vm.generateQuizList();
    setState(() { selectedOption = null; isChecking = false; showScorePop = false; });
    vm.resetQuiz();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizView(quizList: newList),
          settings: const RouteSettings(name: 'QuizView'),
        )
    );
  }

  void _startRetryQuiz(List<WordModel> retryList) {
    final vm = context.read<QuizViewModel>();
    AdMobService.loadInterstitialAd();
    setState(() { selectedOption = null; isChecking = false; showScorePop = false; });
    vm.resetQuiz();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizView(quizList: retryList, isReviewMode: true),
          settings: const RouteSettings(name: 'QuizView'),
        )
    );
  }
}
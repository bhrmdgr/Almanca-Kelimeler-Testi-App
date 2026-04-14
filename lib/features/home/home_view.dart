import 'dart:math' as math;
import 'dart:ui';
import 'package:almanca_kelime_testi/features/admob_widget/smart_banner_widget.dart';
import 'package:almanca_kelime_testi/features/home/home_model.dart';
import 'package:almanca_kelime_testi/features/home/widgets/avatar_selection_view.dart';
import 'package:almanca_kelime_testi/features/home/widgets/level_up_dialog.dart';
import 'package:almanca_kelime_testi/features/home/widgets/score_card_widget.dart';
import 'package:almanca_kelime_testi/features/home/widgets/announcement_widget.dart';
import 'package:almanca_kelime_testi/features/settings/settings_view_model.dart';
import 'package:almanca_kelime_testi/helpers/rank_manager/rank_manager.dart';
import 'package:almanca_kelime_testi/helpers/routers/routers.dart';
import 'package:almanca_kelime_testi/service/admob/admob_service.dart';
import 'package:almanca_kelime_testi/service/firebase/leaderboard_service.dart';
import 'package:almanca_kelime_testi/service/firebase/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ EKLENDİ
import 'home_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int? _previousXP;

  // ✅ KESİN ÇÖZÜM: Statik bellek kilitleri (Session bazlı koruma)
  static bool _isPickerActive = false;
  static bool _avatarSetInThisSession = false;
  static bool _goalSetInThisSession = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _initialLoad();
    });
  }

  Future<void> _initialLoad() async {
    await context.read<HomeViewModel>().fetchUserData();
    if (!mounted) return;

    final data = context.read<HomeViewModel>().userData;
    if (data != null) {
      _previousXP = data.totalXP.toInt();
    }

    final NotificationService notifService = NotificationService();
    await notifService.requestPermissions();
    if (!mounted) return;

    await notifService.initForegroundHandler();
    notifService.listenToTokenRefresh();
    await notifService.updateFcmToken();

    _checkUserDataStatus();
  }

  void _handleRankUp(int currentXP) {
    if (_previousXP != null && currentXP > _previousXP!) {
      final oldRank = RankManager.getRank(_previousXP!);
      final newRank = RankManager.getRank(currentXP);

      if (oldRank['title'] != newRank['title']) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => LevelUpDialog(rank: newRank),
            );
          }
        });
      }
    }
    _previousXP = currentXP;
  }

  void _checkUserDataStatus() async {
    if (!mounted || _isPickerActive) return;

    final data = context.read<HomeViewModel>().userData;
    final prefs = await SharedPreferences.getInstance();

    // Kalıcı kontrol: Hem Firestore hem de Yerel hafıza (App Check hatasına karşı sigorta)
    bool hasLocalAvatar = prefs.getBool('local_avatar_done') ?? false;
    bool hasLocalGoal = prefs.getBool('local_goal_done') ?? false;

    if (data == null) return;

    // 1. Avatar Kontrolü
    if ((data.avatarPath == null || data.avatarPath!.isEmpty) &&
        !_avatarSetInThisSession && !hasLocalAvatar) {
      _showAvatarSelection();
      return;
    }

    // 2. Hedef Kontrolü
    if (data.dailyGoal == 0 && !_goalSetInThisSession && !hasLocalGoal) {
      _showGoalSelectionDialog();
      return;
    }
  }

  void _showAvatarSelection() async {
    if (_isPickerActive) return;
    setState(() => _isPickerActive = true);

    final selectedAvatar = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarSelectionView(),
    );

    if (mounted) {
      if (selectedAvatar != null) {
        // ✅ Yerel mühürü bas
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('local_avatar_done', true);
        _avatarSetInThisSession = true;

        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid ?? "guest_user";
        bool isGuest = user?.isAnonymous ?? true;

        await context.read<HomeViewModel>().updateAvatar(uid, selectedAvatar, isGuest);

        setState(() => _isPickerActive = false);
        _checkUserDataStatus(); // Varsa bir sonraki (Goal) adıma geç
      } else {
        setState(() => _isPickerActive = false);
      }
    }
  }

  void _showGoalSelectionDialog() {
    if (_isPickerActive) return;
    setState(() => _isPickerActive = true);

    final List<int> defaultGoals = [20, 50, 100, 200];
    final TextEditingController customController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5D3FD3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.track_changes_rounded, size: 40, color: Color(0xFF5D3FD3)),
            ),
            const SizedBox(height: 15),
            const Text("Günlük Hedefini Belirle",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Günde kaç yeni kelime öğrenmek istersin?",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            Wrap(
              spacing: 12, runSpacing: 12,
              alignment: WrapAlignment.center,
              children: defaultGoals.map((goal) => GestureDetector(
                onTap: () async {
                  // ✅ Yerel mühürü bas
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('local_goal_done', true);
                  _goalSetInThisSession = true;

                  if (mounted) {
                    context.read<HomeViewModel>().setDailyGoal(goal);
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF5D3FD3).withOpacity(0.2)),
                  ),
                  child: Text("$goal", style: const TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: customController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Özel hedef gir...",
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_circle_right_rounded, color: Color(0xFF5D3FD3), size: 30),
                  onPressed: () async {
                    int? customGoal = int.tryParse(customController.text);
                    if (customGoal != null && customGoal > 0) {
                      // ✅ Yerel mühürü bas
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('local_goal_done', true);
                      _goalSetInThisSession = true;

                      if (mounted) {
                        context.read<HomeViewModel>().setDailyGoal(customGoal);
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isPickerActive = false);
    });
  }

  // --- Arena/Leaderboard Alert Metodu ---
  void _showArenaDialog(BuildContext context, Map<String, List<DocumentSnapshot>> data, Color themeColor) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, a2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: _buildPremiumDialogBody(context, data, themeColor),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumDialogBody(BuildContext context, Map<String, List<DocumentSnapshot>> data, Color themeColor) {
    final topPlayerDoc = (data['topOne']?.isNotEmpty ?? false) ? data['topOne']![0] : null;
    final List<DocumentSnapshot> aboveList = data['above'] ?? [];
    final List<DocumentSnapshot> belowList = data['below'] ?? [];
    final viewModel = context.read<HomeViewModel>();
    final userData = viewModel.userData!;

    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(33)),
            ),
            child: Column(
              children: [
                Text(
                  "ARENA SIRALAMASI",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: themeColor),
                ),
                const SizedBox(height: 15),
                if (topPlayerDoc != null) _buildChampionCard(topPlayerDoc),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              children: [
                if (aboveList.isNotEmpty) ...[
                  ...aboveList.map((doc) => _buildAlertItem(doc, themeColor, isMe: false, userData: userData)),
                  _buildSmallArrow(),
                ],
                _buildAlertItem(null, themeColor, isMe: true, userData: userData),
                if (belowList.isNotEmpty) ...[
                  _buildSmallArrow(),
                  ...belowList.map((doc) => _buildAlertItem(doc, themeColor, isMe: false, userData: userData)),
                ],
                if (aboveList.isEmpty && belowList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text("Sıralamada henüz kimse yok.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("KAPAT", style: TextStyle(color: themeColor, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSmallArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFFB8860B), size: 18),
    );
  }

  Widget _buildChampionCard(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    final int score = data['totalScore'] ?? 0;
    final rankInfo = RankManager.getRank(score);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFB8860B).withOpacity(0.15), const Color(0xFFB8860B).withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFB8860B), size: 28),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(data['avatar'] ?? data['avatarPath'] ?? ""),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['username'] ?? "Lider", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 14)),
                Text("${rankInfo['icon']} ${rankInfo['title']}", style: TextStyle(color: rankInfo['color'], fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
          ),
          Text("$score XP", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(DocumentSnapshot? doc, Color themeColor, {required bool isMe, required HomeModel userData}) {
    final Map<String, dynamic> data = (isMe ? null : doc?.data() as Map<String, dynamic>?) ?? {};
    final String name = isMe ? userData.username : (data['username'] ?? "Oyuncu");
    final int score = isMe ? userData.totalXP.toInt() : (data['totalScore'] ?? 0);
    final String? avatar = isMe ? userData.avatarPath : (data['avatar'] ?? data['avatarPath']);
    final rankInfo = RankManager.getRank(score);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? themeColor.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isMe ? themeColor.withOpacity(0.4) : Colors.transparent, width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 16,
              backgroundImage: avatar != null ? AssetImage(avatar) : null
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                Text("${rankInfo['icon']} ${rankInfo['title']}", style: TextStyle(color: rankInfo['color'], fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text("$score", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13)),
          const SizedBox(width: 2),
          const Text("XP", style: TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final data = viewModel.userData;

    if (viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (data == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 20),
              const Text("Verilere ulaşılamıyor.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("Lütfen internet bağlantınızı kontrol edin."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => viewModel.fetchUserData(),
                child: const Text("Tekrar Dene"),
              )
            ],
          ),
        ),
      );
    }

    _handleRankUp(data.totalXP.toInt());
    final rank = RankManager.getRank(data.totalXP.toInt());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F9FF), Color(0xFFE8EBFF)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(data, rank),
                    const SizedBox(height: 15),

                    Text(
                      "İstatistiklerin",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade900),
                    ),
                    const SizedBox(height: 15),
                    ScoreCardWidget(
                      userData: data,
                      onShowLeaderboard: () async {
                        if (data.isPremium) {
                          final leaderboardData = await LeaderboardService()
                              .getNeighboringLeaderboard(data.totalXP.toInt());
                          if (mounted) {
                            _showArenaDialog(context, leaderboardData, rank['color']);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Arena ligi için Premium üye olmalısınız.")),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 15),
                    _buildDailyGoalCard(data),
                    const SizedBox(height: 15),
                    _buildStartButton(),
                    const SizedBox(height: 15),
                    _buildStatGrid(data),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          if (viewModel.pendingAnnouncement != null)
            AnnouncementWidget(data: viewModel.pendingAnnouncement!),
        ],
      ),
      bottomNavigationBar: !data.isPremium
          ? Container(
        color: Colors.white, // Alt barın rengi
        child: SafeArea(
          bottom: Theme.of(context).platform == TargetPlatform.android,
          top: false,
          child: SmartBannerWidget(adUnitId: AdMobService.bannerAdUnitIdHome),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(HomeModel data, Map<String, dynamic> rank) {
    return Row(
      children: [
        GestureDetector(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [rank['color'], const Color(0xFF2575FC)]),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              backgroundImage: (data.avatarPath != null && data.avatarPath!.isNotEmpty)
                  ? AssetImage(data.avatarPath!)
                  : null,
              child: (data.avatarPath == null || data.avatarPath!.isEmpty)
                  ? const Icon(Icons.person_rounded, color: Color(0xFF5D3FD3), size: 30)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(data.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                if (data.isPremium) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 18),
                ],
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildCircularIconButton(Icons.settings_suggest_rounded),
      ],
    );
  }

  Widget _buildCircularIconButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRouters.settingsView);
          if (mounted) {
            final settingsVM = context.read<SettingsViewModel>();
            if (settingsVM.hasChanges) {
              await context.read<HomeViewModel>().fetchUserData();
              settingsVM.clearChanges();
            }
          }
        },
        icon: Icon(icon, color: Colors.blueGrey.shade700),
      ),
    );
  }

  Widget _buildStatGrid(HomeModel data) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, AppRouters.learnedWords);
              if (mounted) context.read<HomeViewModel>().fetchUserData();
            },
            child: _buildGlassBox("Öğrendiğim", "${data.learnedWordsCount}", const Color(0xFF00B09B), const Color(0xFF96C93D), Icons.auto_awesome_rounded),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, AppRouters.wrongWords);
              if (mounted) context.read<HomeViewModel>().fetchUserData();
            },
            child: _buildGlassBox("Yanlışlarım", "${data.wrongWordsCount}", const Color(0xFFFF416C), const Color(0xFFFF4B2B), Icons.sentiment_very_dissatisfied_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassBox(String title, String count, Color c1, Color c2, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: c1.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(HomeModel data) {
    if (data.dailyGoal <= 0) {
      return GestureDetector(
        onTap: () => _showGoalSelectionDialog(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF5D3FD3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFF5D3FD3).withOpacity(0.2), width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: Color(0xFF5D3FD3), size: 30),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Günlük Hedef Belirle",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5D3FD3))),
                    Text("Gelişimini takip etmek için tıkla.",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF5D3FD3)),
            ],
          ),
        ),
      );
    }

    double progress = (data.completedTasks / data.dailyGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Günlük Hedef", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D3FD3)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 5),
              Text("${data.completedTasks}/${data.dailyGoal} Kelime Tamamlandı",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF5038ED).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRouters.quizOptions);
          if (mounted) context.read<HomeViewModel>().fetchUserData();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5038ED),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 65),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled_rounded, size: 28),
            SizedBox(width: 12),
            Text("QUIZ'E BAŞLA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }
}
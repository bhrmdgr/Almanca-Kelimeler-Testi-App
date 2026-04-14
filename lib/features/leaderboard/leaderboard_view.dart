import 'package:almanca_kelime_testi/features/home/home_model.dart';
import 'package:almanca_kelime_testi/helpers/rank_manager/rank_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'leaderboard_view_model.dart';

class LeaderboardView extends StatefulWidget {
  final HomeModel userData;
  const LeaderboardView({super.key, required this.userData});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> with SingleTickerProviderStateMixin {
  final String _defaultAvatar = "assets/avatars/boy-avatar-1.png";
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

    Future.microtask(() => context
        .read<LeaderboardViewModel>()
        .fetchLeaderboardData(
        widget.userData.totalXP,
        widget.userData.weeklyScore
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ✅ AKTARILAN: Kullanıcıyı Bildirme Diyaloğu
  void _showReportDialog(String targetUsername) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kullanıcıyı Bildir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "'$targetUsername' isimli kullanıcının profil isminde uygunsuz içerik olduğunu bildirmek istiyor musunuz?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("VAZGEÇ", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('reports').add({
                'reporter': widget.userData.username,
                'reportedUser': targetUsername,
                'reason': 'Uygunsuz Kullanıcı Adı',
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bildiriminiz incelenmek üzere alındı.")),
                );
              }
            },
            child: const Text("BİLDİR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getValidAvatar(String? path) {
    if (path == null || path.trim().isEmpty) return _defaultAvatar;
    if (path.contains('assets/')) return path;
    return "assets/avatars/$path";
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LeaderboardViewModel>();
    final rank = RankManager.getRank(widget.userData.totalXP.toInt());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rank['color'].withOpacity(0.6), const Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildModernTabSelector(),
              const SizedBox(height: 10),

              if (viewModel.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
              else
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => _tabController.animateTo(index),
                    children: [
                      _buildLeaderboardList(
                          viewModel,
                          isWeekly: true,
                          title: "Haftalık Sıralaman: ${viewModel.myWeeklyRank ?? '...'}"
                      ),
                      _buildLeaderboardList(
                          viewModel,
                          isWeekly: false,
                          title: "Genel Sıralaman: ${viewModel.myRank ?? '...'}"
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabSelector() {
    final rank = RankManager.getRank(widget.userData.totalXP.toInt());
    final Color userRankColor = rank['color'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => _pageController.animateToPage(index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [userRankColor, userRankColor.withBlue(150).withRed(100)],
          ),
          boxShadow: [
            BoxShadow(color: userRankColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: "HAFTALIK"), Tab(text: "GENEL")],
      ),
    );
  }

  Widget _buildLeaderboardList(LeaderboardViewModel viewModel, {required bool isWeekly, required String title}) {
    // ✅ AKTARILAN: Haftalık podyumda ŞAMPİYONLAR, Genel podyumda TOP PLAYERS
    final podiumData = isWeekly ? viewModel.lastWeekChampions : viewModel.topPlayers;
    final aboveMe = isWeekly ? viewModel.aboveMeWeekly : viewModel.aboveMe;
    final belowMe = isWeekly ? viewModel.belowMeWeekly : viewModel.belowMe;
    final myRank = isWeekly ? viewModel.myWeeklyRank : viewModel.myRank;

    List<DocumentSnapshot?> fullPotentials = [];
    fullPotentials.addAll(aboveMe);
    fullPotentials.add(null); // Burası 'Ben'
    fullPotentials.addAll(belowMe);

    // İngilizcedeki 7 limitini buraya da ekledik
    final List<DocumentSnapshot?> displayList = fullPotentials.take(7).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildPodium(podiumData, isWeekly: isWeekly),
        const SizedBox(height: 25),
        _buildSectionTitle(isWeekly ? "BU HAFTAKİ REKABET 🔥" : title),
        const SizedBox(height: 10),

        ...displayList.map((doc) {
          if (doc == null) {
            return _buildPlayerCard(null, isMe: true, currentRank: myRank, isWeekly: isWeekly);
          }

          int? calculatedRank;
          if (myRank != null) {
            int myPosInOriginal = fullPotentials.indexOf(null);
            int docPosInOriginal = fullPotentials.indexOf(doc);
            calculatedRank = myRank + (docPosInOriginal - myPosInOriginal);
          }

          return _buildPlayerCard(doc, isMe: false, currentRank: calculatedRank, isWeekly: isWeekly);
        }),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "ARENA LİGİ",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPodium(List podiumData, {required bool isWeekly}) {
    if (podiumData.isEmpty) return const SizedBox.shrink();

    List<Widget> podiumItems = [];
    if (podiumData.length >= 2) podiumItems.add(_buildPodiumItem(podiumData[1], 2, isWeekly: isWeekly));
    podiumItems.add(_buildPodiumItem(podiumData[0], 1, isWeekly: isWeekly));
    if (podiumData.length >= 3) podiumItems.add(_buildPodiumItem(podiumData[2], 3, isWeekly: isWeekly));

    return Column(
      children: [
        if (isWeekly)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Text(
                "GEÇEN HAFTANIN ŞAMPİYONLARI 🏆",
                style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: podiumItems,
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumItem(dynamic item, int rank, {required bool isWeekly}) {
    final Map<String, dynamic> data = item is DocumentSnapshot
        ? (item.data() as Map<String, dynamic>)
        : (item as Map<String, dynamic>);

    final bool isMe = (data['username'] == widget.userData.username);
    final String name = isMe ? widget.userData.username : (data['username'] ?? "...");

    final String? avatarData = data['avatar'] ?? data['avatarPath'];
    final String avatar = isMe ? _getValidAvatar(widget.userData.avatarPath) : _getValidAvatar(avatarData);

    final int scoreKey = isWeekly ? (data['score'] ?? 0) : (data[isWeekly ? 'weeklyScore' : 'totalScore'] ?? 0);
    final displayScore = scoreKey.toInt();

    double avatarRadius = rank == 1 ? 45 : 35;
    double iconSize = rank == 1 ? 40 : 30;
    Color rankColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey.shade100 : const Color(0xFFFF9A00));
    IconData podiumIcon = rank == 1 ? Icons.emoji_events_rounded : Icons.workspace_premium_rounded;

    return Transform.translate(
      offset: rank == 1 ? const Offset(0, -20) : Offset.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(podiumIcon, color: rankColor, size: iconSize),
          const SizedBox(height: 5),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius + 3,
                backgroundColor: rankColor,
                child: CircleAvatar(radius: avatarRadius, backgroundImage: AssetImage(avatar)),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: rankColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1)),
                  child: Text(rank.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: TextStyle(color: Colors.white, fontSize: rank == 1 ? 14 : 12, fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal)),
              if (!isMe)
                GestureDetector(
                  onTap: () => _showReportDialog(name),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.error_outline_rounded, color: Colors.white24, size: 14),
                  ),
                ),
            ],
          ),
          Text("$displayScore XP", style: TextStyle(color: rankColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(dynamic doc, {required bool isMe, int? currentRank, required bool isWeekly}) {
    String name;
    int displayScore;
    int rankCalcScore;
    String avatar;

    if (isMe) {
      name = widget.userData.username;
      displayScore = isWeekly ? widget.userData.weeklyScore.toInt() : widget.userData.totalXP.toInt();
      rankCalcScore = widget.userData.totalXP.toInt();
      avatar = _getValidAvatar(widget.userData.avatarPath);
    } else {
      final data = doc.data() as Map<String, dynamic>;
      name = data['username'] ?? "Öğrenci";
      displayScore = (data[isWeekly ? 'weeklyScore' : 'totalScore'] ?? 0).toInt();
      rankCalcScore = (data['totalScore'] ?? 0).toInt();
      final String? avatarData = data['avatar'] ?? data['avatarPath'];
      avatar = _getValidAvatar(avatarData);
    }

    final rankInfo = RankManager.getRank(rankCalcScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isMe ? const Color(0xFF6366F1).withOpacity(0.5) : Colors.white.withOpacity(0.05), width: isMe ? 2 : 1),
      ),
      child: Row(
        children: [
          SizedBox(width: 35, child: Text(currentRank != null ? "#$currentRank" : "", style: TextStyle(color: isMe ? Colors.amber : Colors.white38, fontWeight: FontWeight.w900, fontSize: 12))),
          CircleAvatar(radius: 22, backgroundImage: AssetImage(avatar)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${rankInfo['icon']} ${rankInfo['title']}".toUpperCase(), style: TextStyle(color: rankInfo['color'], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
          Row(
            children: [
              Text("$displayScore XP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(width: 2),
              if (!isMe)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.error_outline_rounded, color: Colors.white24, size: 16),
                  onPressed: () => _showReportDialog(name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
    );
  }
}
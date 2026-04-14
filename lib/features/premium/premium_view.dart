import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/settings_view_model.dart';
import '../home/home_view_model.dart';
import 'premium_view_model.dart';

class PremiumView extends StatelessWidget {
  const PremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVM = Provider.of<SettingsViewModel>(context, listen: false);
    final homeVM = Provider.of<HomeViewModel>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => PremiumViewModel()..init(homeVM.userData, settingsVM),
      child: Consumer<PremiumViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            body: Stack(
              children: [
                _buildBackground(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(context, vm),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _buildHeader(vm.isAlreadyPremium),

                              if (vm.isAlreadyPremium) _buildExpiryInfo(vm),

                              const SizedBox(height: 30),
                              _buildFeatures(),
                              const SizedBox(height: 30),

                              if (!vm.isAlreadyPremium) _buildPriceCards(vm),

                              const SizedBox(height: 20),
                              _buildLegalLinks(vm),
                              const SizedBox(height: 20),

                              if (!vm.isAlreadyPremium || vm.isAutoRenew)
                                _buildMainButton(context, vm, settingsVM),

                              const SizedBox(height: 20),

                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (vm.isLoading) _buildLoadingOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpiryInfo(PremiumViewModel vm) {
    if (vm.expiryDateText == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.isAutoRenew ? "SONRAKİ ÖDEME TARİHİ" : "ERİŞİM BİTİŞ TARİHİ",
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.expiryDateText!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                  ),
                ),
                if (!vm.isAutoRenew)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Otomatik yenileme kapalı.",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, PremiumViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          if (Platform.isIOS && !vm.isAlreadyPremium)
            TextButton(
              onPressed: () => vm.restorePurchases(),
              child: const Text(
                "Geri Yükle",
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isPremium) {
    return Column(
      children: [
        Icon(
          isPremium ? Icons.verified_user_rounded : Icons.stars_rounded,
          color: Colors.amber,
          size: 80,
        ),
        const SizedBox(height: 10),
        Text(
          isPremium ? "PREMIUM ÜYESİNİZ" : "PREMIUM'A GEÇ",
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5
          ),
        ),
        Text(
          isPremium
              ? "Tüm ayrıcalıkların keyfini çıkarıyorsunuz."
              : "Dil öğrenme deneyimini zirveye taşı",
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.block, 'text': 'Tamamen Reklamsız Deneyim'},
      {'icon': Icons.leaderboard, 'text': 'Global Sıralamada Yerini Gör'},
      {'icon': Icons.offline_bolt, 'text': 'Sınırsız Quiz ve Kelime Erişimi'},
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(f['icon'], color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 15),
            Text(f['text'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPriceCards(PremiumViewModel vm) {
    return Row(
      children: [
        Expanded(child: _priceCard(vm, "AYLIK", vm.monthlyPrice, vm.service.monthlyId)),
        const SizedBox(width: 15),
        Expanded(child: _priceCard(vm, "YILLIK", vm.yearlyPrice, vm.service.yearlyId, isBestValue: true)),
      ],
    );
  }

  Widget _priceCard(PremiumViewModel vm, String title, String price, String plan, {bool isBestValue = false}) {
    bool isSelected = vm.selectedPlan == plan;
    return GestureDetector(
      onTap: () => vm.selectPlan(plan), // ✅ Metot burada çağrılıyor
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.amber : Colors.white24, width: 2),
        ),
        child: Column(
          children: [
            if (isBestValue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                child: const Text("EN POPÜLER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: isSelected ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(price, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // PremiumView.dart içinde ilgili kısımları bu şekilde güncelle:

  Widget _buildMainButton(BuildContext context, PremiumViewModel vm, SettingsViewModel settingsVM) {
    return Column(
      children: [
        // Apple için abonelik süresini butonun hemen üstünde netleştiriyoruz
        if (!vm.isAlreadyPremium)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              vm.selectedPlan.contains('yillik') ? "1 Yıllık Abonelik" : "1 Aylık Abonelik",
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: vm.isAlreadyPremium ? Colors.white12 : Colors.amber,
              foregroundColor: vm.isAlreadyPremium ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              if (vm.isAlreadyPremium) {
                vm.manageSubscription();
              } else {
                vm.startPurchase(context, settingsVM);
              }
            },
            child: Text(
              vm.isAlreadyPremium ? "ABONELİĞİ YÖNET" : "ABONELİĞİ BAŞLAT",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLinks(PremiumViewModel vm) {
    return Column(
      children: [
        // Apple'ın istediği standart açıklama metni (KRİTİK)
        if (Platform.isIOS && !vm.isAlreadyPremium)

        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              // Linkin App Store Connect'teki Privacy URL ile birebir aynı olduğundan emin ol
                onPressed: () => vm.launchURL("https://sites.google.com/view/ingilizcekelimelertesti/ingilizce-kelimeler-testi-gizlilik-politikas%C4%B1"),
                child: const Text("Gizlilik Politikası", style: TextStyle(color: Colors.white54, fontSize: 11, decoration: TextDecoration.underline))
            ),
            const Text("|", style: TextStyle(color: Colors.white54)),
            TextButton(
                onPressed: () => vm.launchURL("https://sites.google.com/view/ingilizcekelimelertesti/ingilizce-kelimeler-testi-kullan%C4%B1m-ko%C5%9Fullar%C4%B1"),
                child: const Text("Kullanım Koşulları", style: TextStyle(color: Colors.white54, fontSize: 11, decoration: TextDecoration.underline))
            ),
            if (Platform.isIOS) ...[
              const Text("|", style: TextStyle(color: Colors.white54)),
              TextButton(
                  onPressed: () => vm.launchURL("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
                  child: const Text("EULA", style: TextStyle(color: Colors.white54, fontSize: 11, decoration: TextDecoration.underline))
              ),
            ],
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            "Ödeme, satın alma onayının ardından iTunes Hesabınızdan tahsil edilecektir. Abonelik, cari dönemin bitiminden en az 24 saat önce otomatik yenileme kapatılmadığı sürece otomatik olarak yenilenir. Hesap, cari dönemin bitiminden 24 saat önce yenileme için ücretlendirilecektir.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );
  }
}
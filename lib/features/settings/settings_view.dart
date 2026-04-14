import 'package:almanca_kelime_testi/helpers/routers/routers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_view_model.dart';
import 'widgets/target_alert.dart';
import 'widgets/notification_alert.dart';
import 'widgets/privacy_policy_alert.dart'; // Yeni eklendi
import 'widgets/terms_of_use_alert.dart';   // Yeni eklendi

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});



  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();


    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        title: const Text("Ayarlar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Hesap"),
            _buildSettingItem(Icons.person_outline_rounded, "Profil Ayarları", "Adın, e-postan ve telefonun", () {

              if (viewModel.isGuest) {
                // Misafir ise sadece mesaj göster
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bu özelliği kullanabilmek için kayıtlı kullanıcı olmalısınız. Eğer yeni kayıt olduysanız lütfen uygulamayı YENİDEN başlatın."),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF5D3FD3), // Uygulama temanıza uygun renk
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                // Kayıtlı kullanıcı ise profil sayfasına git
                Navigator.pushNamed(context, AppRouters.profile);
              }
            }),

            _buildSettingItem(
                Icons.track_changes_rounded,
                "Hedef Güncellemesi",
                "Günlük hedef: ${viewModel.dailyGoal} kelime",
                    () => _showGoalUpdateDialog(viewModel, context)
            ),

            _buildSettingItem(
                Icons.notifications_none_rounded,
                "Ses ve Bildirim Ayarları",
                "Hatırlatıcıları yönet",
                    () => _showNotificationDialog(context)
            ),

            const SizedBox(height: 25),
            _buildSectionTitle("Uygulama"),
            /*_buildSettingItem(Icons.workspace_premium_rounded, "Premium'a Geç", "Reklamsız ve sınırsız deneyim", () {
              if (viewModel.isGuest) {
                // Misafir ise sadece mesaj göster
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bu özelliği kullanabilmek için kayıtlı kullanıcı olmalısınız."),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF5D3FD3), // Uygulama temanıza uygun renk
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                Navigator.pushNamed(context, AppRouters.premium);
              }
            }, isPremium: true),*/
            _buildSettingItem(Icons.help_outline_rounded, "Yardım ve Destek", "Bize soru sor", () {
              Navigator.pushNamed(context, AppRouters.help);
            }),

            const SizedBox(height: 25),
            _buildSectionTitle("Yasal"),
            _buildSettingItem(
                Icons.privacy_tip_outlined,
                "Gizlilik Politikası",
                "Veri güvenliğiniz hakkında",
                    () => _showPrivacyPolicy(context)
            ),
            _buildSettingItem(
                Icons.description_outlined,
                "Kullanım Koşulları",
                "Uygulama kullanım kuralları",
                    () => _showTermsOfUse(context)
            ),

            const SizedBox(height: 40),
            _buildLogoutButton(viewModel, context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGoalUpdateDialog(SettingsViewModel viewModel, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TargetAlert(
        currentGoal: viewModel.dailyGoal,
        onGoalSelected: (newGoal) {
          viewModel.updateDailyGoal(newGoal);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Yeni hedefin: $newGoal kelime"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF5D3FD3),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationAlert(),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyAlert(),
    );
  }

  void _showTermsOfUse(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TermsOfUseAlert(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isPremium = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPremium ? const Color(0xFFFFD700).withOpacity(0.1) : const Color(0xFFF0F2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isPremium ? const Color(0xFFD4AF37) : const Color(0xFF5D3FD3)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildLogoutButton(SettingsViewModel viewModel, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmDialog(viewModel, context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFFFEBEE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded),
            SizedBox(width: 10),
            Text("Çıkış Yap", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(SettingsViewModel viewModel, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Çıkış Yap", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              // 1. Önce ViewModel üzerinden çıkış işlemini başlat (Bekle)
              await viewModel.signOut();

              if (context.mounted) {
                // 2. TÜM sayfaları (Settings dahil) kapat ve SignIn'e "Kök" sayfa olarak git
                // Bu komut stack'teki her şeyi siler, SignIn'i en alta koyar.
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouters.signIn,
                      (route) => false,
                );
              }
            },
            child: const Text(
                "Evet, Çıkış Yap",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:almanca_kelime_testi/features/home/widgets/avatar_selection_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_view_model.dart';
import '../../../../helpers/theme/theme.dart';
import '../../../../helpers/routers/routers.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProfileViewModel>().fetchUserData());
  }

  // ✅ Yeni: Avatar seçim BottomSheet'ini açan metod
  void _showAvatarSelection() async {
    final selectedAvatar = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarSelectionView(),
    );

    if (selectedAvatar != null && mounted) {
      await context.read<ProfileViewModel>().updateAvatar(selectedAvatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<ProfileViewModel>();
    final user = viewModel.userData;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: viewModel.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildPremiumAvatar(user, theme), // ✅ User map'i gönderildi
                const SizedBox(height: 40),
                _buildModernSection(
                  "TEMEL BİLGİLER",
                  [
                    _buildEditableItem(
                      icon: Icons.badge_outlined,
                      label: "Ad Soyad",
                      value: user?['fullName'] ?? "-",
                      isEditable: false,
                      theme: theme,
                    ),
                    _buildEditableItem(
                      icon: Icons.alternate_email_rounded,
                      label: "Kullanıcı Adı",
                      value: "@${user?['username'] ?? "-"}",
                      onTap: () => _showEditDialog("username", "Kullanıcı Adı", user?['username']),
                      theme: theme,
                    ),
                  ],
                  theme,
                ),
                const SizedBox(height: 25),
                _buildModernSection(
                  "İLETİŞİM VE GÜVENLİK",
                  [
                    _buildEditableItem(
                      icon: Icons.mail_outline_rounded,
                      label: "E-posta",
                      value: user?['email'] ?? "-",
                      isEditable: true,
                      onTap: () => _showEmailEditDialog(user?['email']),
                      theme: theme,
                    ),
                    /*
                    _buildEditableItem(
                      icon: Icons.phone_iphone_rounded,
                      label: "Telefon",
                      value: user?['phoneNumber'] ?? "-",
                      onTap: () => _showEditDialog("phoneNumber", "Telefon", user?['phoneNumber']),
                      theme: theme,
                    ),
                     */
                  ],
                  theme,
                ),
                const SizedBox(height: 35),
                _buildPremiumPasswordButton(viewModel, theme),
                const SizedBox(height: 20),

                // HESAP SİLME BUTONU
                TextButton.icon(
                  onPressed: () => _showDeleteAccountDialog(context, viewModel),
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  label: const Text("Hesabımı Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (viewModel.isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- HESAP SİLME DİYALOĞU ---
  // ProfileView.dart içindeki _showDeleteAccountDialog metodunu güncelle:

  void _showDeleteAccountDialog(BuildContext context, ProfileViewModel viewModel) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
            "Hesabımı Kalıcı Olarak Sil",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
        ),
        // Taşmayı önlemek için SingleChildScrollView ekliyoruz
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Sadece içeriği kadar yer kaplar
            children: [
              const Text(
                "Bu işlem geri alınamaz. Sıralamadaki yeriniz ve tüm verileriniz silinecektir.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Mevcut Şifreniz",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_reset),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Vazgeç")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (passwordController.text.trim().isEmpty) return;

              bool success = await viewModel.deleteAccount(passwordController.text.trim());

              if (success && context.mounted) {
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  AppRouters.signIn,
                      (route) => false,
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(viewModel.errorMessage ?? "Hata!")),
                );
              }
            },
            child: const Text("Verilerimi Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ DÜZELTME: Avatar artık seçilen görseli gösteriyor ve tıklanabiliyor
  Widget _buildPremiumAvatar(Map<String, dynamic>? user, ThemeData theme) {
    final String name = user?['username'] ?? "?";
    final String? avatarPath = user?['avatarPath'];

    return Center(
      child: GestureDetector(
        onTap: _showAvatarSelection,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.surfaceColor,
                backgroundImage: (avatarPath != null && avatarPath.isNotEmpty)
                    ? AssetImage(avatarPath)
                    : null,
                child: (avatarPath == null || avatarPath.isEmpty)
                    ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                )
                    : null,
              ),
            ),
            // Düzenleme simgesi
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection(String title, List<Widget> children, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildEditableItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    VoidCallback? onTap,
    bool isEditable = true,
  }) {
    return InkWell(
      onTap: isEditable ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (isEditable) Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPasswordButton(ProfileViewModel viewModel, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: () => _showPasswordUpdateDialog(context, viewModel, theme),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text("Şifre ve Güvenlik Ayarları", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String field, String label, String? currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("$label Güncelle"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Yeni $label giriniz", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              await context.read<ProfileViewModel>().updateUserInfo(field, controller.text.trim());
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _showEmailEditDialog(String? currentEmail) {
    final controller = TextEditingController(text: currentEmail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("E-posta Güncelle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("E-posta adresinizi değiştirdiğinizde giriş bilgileriniz de güncellenecektir.",
                style: TextStyle(fontSize: 12, color: Colors.orange)),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: "Yeni E-posta", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty || !controller.text.contains("@")) return;
              Navigator.pop(context);
              await context.read<ProfileViewModel>().updateEmail(controller.text.trim());
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  void _showPasswordUpdateDialog(BuildContext context, ProfileViewModel viewModel, ThemeData theme) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Şifre Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Yeni Şifre (Min 6 Karakter)",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                bool res = await viewModel.sendResetMail();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res ? "Sıfırlama maili gönderildi." : "Hata oluştu."), behavior: SnackBarBehavior.floating));
                }
              },
              child: const Text("Şifremi Unuttum? Mail Gönder"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 6) return;
              bool success = await viewModel.updatePassword(passController.text);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Şifre güncellendi." : viewModel.errorMessage ?? "Hata."), behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text("Şifreyi Değiştir"),
          ),
        ],
      ),
    );
  }
}
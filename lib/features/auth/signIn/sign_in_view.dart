import 'package:almanca_kelime_testi/features/auth/signIn/sign_in_view_model.dart';
import 'package:almanca_kelime_testi/helpers/policy/privacy_policy.dart';
import 'package:almanca_kelime_testi/helpers/policy/terms_of_use.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/theme/theme.dart';
import '../../../../helpers/routers/routers.dart';

class SigninView extends StatefulWidget {
  const SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _guestNameController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  void _showPolicyContent(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  // --- ŞİFRE SIFIRLAMA DİYALOĞU ---
  void _showForgotPasswordDialog(SignInViewModel viewModel, ThemeData theme) {
    final TextEditingController resetEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Şifremi Unuttum", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Şifrenizi sıfırlamak için kayıtlı e-posta adresinizi girin. Size bir bağlantı göndereceğiz.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10,),
            Text(
              "Eğer bağlantıyı göremezseniz spam klasörünü kontrol etmeyi unutmayın",
              style: TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: resetEmailController,
              hint: "E-posta",
              icon: Icons.mail_outline,
              theme: theme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              bool success = await viewModel.resetPassword(email);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "Şifre sıfırlama bağlantısı e-postanıza gönderildi."
                        : (viewModel.errorMessage ?? "Bir hata oluştu.")),
                    backgroundColor: success ? Colors.green : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = Provider.of<SignInViewModel>(context);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(theme),
                    const SizedBox(height: 30),
                    Text(
                      "Merhaba!",
                      style: theme.textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Kelime hazneni geliştirmeye hazır mısın?",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    if (viewModel.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _emailController,
                      hint: "E-posta",
                      icon: Icons.mail_outline,
                      theme: theme,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _passwordController,
                      hint: "Şifre",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      theme: theme,
                    ),

                    // --- ŞİFREMİ UNUTTUM BUTONU ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(viewModel, theme),
                        child: Text(
                          "Şifremi Unuttum",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), // Boşluk düzenlendi

                    ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                        bool success = await viewModel.login(
                          _emailController.text,
                          _passwordController.text,
                        );
                        if (success && mounted) {
                          Navigator.pushReplacementNamed(context, AppRouters.home);
                        } else if (!success && mounted && viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(viewModel.errorMessage!),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: viewModel.isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text("Giriş Yap"),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: () {
                        viewModel.clearError();
                        Navigator.pushNamed(context, AppRouters.signUp);
                      },
                      child: Text(
                        "Hesabın yok mu? Kayıt Ol",
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 30),
                    _buildDivider(),
                    const SizedBox(height: 30),

                    OutlinedButton(
                      onPressed: () => _showGuestNameDialog(viewModel, theme),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      child: const Text("Misafir Olarak Devam Et"),
                    ),
                  ],
                ),
              ),
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

  Widget _buildLogo(ThemeData theme) {
    return Container(
      height: 140, // Biraz daha belirgin olması için büyütüldü
      width: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white, // Logonun arkasında temiz bir zemin
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 4,
        ),
      ),
      // ClipRRect veya clipBehavior kullanarak görseli yuvarlağa hapsediyoruz
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(0.0), // Logo ile kenarlar arasında nefes payı
          child: Image.asset(
            "assets/images/app-icon.png",
            fit: BoxFit.contain, // Logonun kesilmeden sığmasını sağlar
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.7)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "VEYA",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  void _showGuestNameDialog(SignInViewModel viewModel, ThemeData theme) {
    bool isAccepted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // Ekran kenarlarından pay bırakarak taşmayı zorlaştırır
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              backgroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Hoş Geldiniz"),
                ],
              ),
              // İçeriği SingleChildScrollView içine alıyoruz ki klavye açılınca kaydırılabilsin
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Lütfen bir kullanıcı adı belirleyin:", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _guestNameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Örn: Aslan",
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                    text: "Önemli: Misafir modunda verileriniz yedeklenmez. Uygulama silinirse tüm ilerlemeniz kaybolur. Verilerinizin kaybolmaması için ",
                                  ),
                                  TextSpan(
                                    text: "ÜCRETSİZ kayıt olabilirsiniz.",
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w900,
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pop(context);
                                        viewModel.clearError();
                                        Navigator.pushNamed(context, AppRouters.signUp);
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: isAccepted,
                            onChanged: (value) {
                              setDialogState(() {
                                isAccepted = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: "Kullanım Koşulları",
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showPolicyContent("Kullanım Koşulları", TermsOfUse.content),
                                ),
                                const TextSpan(text: " ve "),
                                TextSpan(
                                  text: "Gizlilik Politikası",
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showPolicyContent("Gizlilik Politikası", PrivacyPolicy.content),
                                ),
                                const TextSpan(text: " metinlerini okudum ve kabul ediyorum."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    viewModel.clearError();
                    _guestNameController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 45),
                    backgroundColor: isAccepted ? null : Colors.grey,
                  ),
                  onPressed: isAccepted
                      ? () async {
                    final name = _guestNameController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(context);
                      bool success = await viewModel.loginAsGuest(name);
                      if (success && mounted) {
                        Navigator.pushReplacementNamed(context, AppRouters.home);
                      } else if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage ?? "Misafir girişi başarısız.")),
                        );
                      }
                    }
                  }
                      : null,
                  child: const Text("Başla"),
                ),
              ],
            );
          }
      ),
    );
  }
}
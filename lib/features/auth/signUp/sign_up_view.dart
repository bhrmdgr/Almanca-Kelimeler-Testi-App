import 'package:almanca_kelime_testi/features/auth/signUp/sign_up_view_model.dart';
import 'package:almanca_kelime_testi/helpers/policy/privacy_policy.dart';
import 'package:almanca_kelime_testi/helpers/policy/terms_of_use.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../helpers/theme/theme.dart';
import '../../../../helpers/routers/routers.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Şifre görünürlük durumları
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Politika onay durumu
  bool _isAccepted = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = Provider.of<SignUpViewModel>(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              Text("Yeni Hesap Oluştur", style: theme.textTheme.displayLarge),
              const SizedBox(height: 10),
              Text("Hemen aramıza katıl ve öğrenmeye başla.", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 40),

              _buildField(_fullNameController, "Ad Soyad", Icons.badge_outlined, theme),
              const SizedBox(height: 15),

              _buildField(_usernameController, "Kullanıcı Adı", Icons.person_outline, theme),
              const SizedBox(height: 15),

              _buildField(_emailController, "E-posta", Icons.mail_outline, theme, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),

              _buildField(
                  _passwordController,
                  "Şifre",
                  Icons.lock_outline,
                  theme,
                  isPassword: true,
                  isVisible: _isPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  }
              ),
              const SizedBox(height: 15),

              _buildField(
                  _confirmPasswordController,
                  "Şifre Tekrar",
                  Icons.lock_reset_outlined,
                  theme,
                  isPassword: true,
                  isVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                  }
              ),

              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isAccepted,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        setState(() => _isAccepted = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontFamily: 'Poppins'),
                        children: [
                          TextSpan(
                            text: "Kullanım Koşulları",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog("Kullanım Koşulları", TermsOfUse.content),
                          ),
                          const TextSpan(text: " ve "),
                          TextSpan(
                            text: "Gizlilik Politikası",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPolicyDialog("Gizlilik Politikası", PrivacyPolicy.content),
                          ),
                          const TextSpan(text: " metinlerini okudum ve kabul ediyorum."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ✅ GÜNCELLEME: Doğrudan signUp metodu çağrılıyor ve başarılıysa Home'a gidiyor.
              ElevatedButton(
                onPressed: (viewModel.isLoading || !_isAccepted) ? null : () async {
                  bool success = await viewModel.signUp(
                    fullName: _fullNameController.text,
                    username: _usernameController.text,
                    email: _emailController.text,
                    password: _passwordController.text,
                    confirmPassword: _confirmPasswordController.text,
                  );

                  if (success && mounted) {
                    Navigator.pushReplacementNamed(context, AppRouters.home);
                  }
                },
                child: viewModel.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Kayıt Ol"),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Zaten hesabın var mı? Giriş Yap",
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String hint,
      IconData icon,
      ThemeData theme,
      {bool isPassword = false,
        bool isVisible = false,
        VoidCallback? onVisibilityToggle,
        TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !isVisible : false,
        keyboardType: keyboardType,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.7)),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade600,
            ),
            onPressed: onVisibilityToggle,
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}
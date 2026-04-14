import 'package:almanca_kelime_testi/service/firebase/auth_service.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Çakışmayı önlemek için SharedPreferences anahtarlarına eklenecek ön ek
  final String _p = "de_";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Telefon doğrulama devre dışı bırakıldığı için bu alanlar artık kullanılmıyor
  String? _verificationId;
  bool get isCodeSent => true; // UI'da kod gönderildi kontrolü varsa hata vermemesi için true

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Yeni Kayıt Metodu: Telefon ve SMS gerektirmez
  Future<bool> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Validasyonlar
    if (!EmailValidator.validate(email)) {
      debugPrint("Geçersiz e-posta formatı");
      return false;
    }

    if (password != confirmPassword) {
      debugPrint("Şifreler eşleşmiyor");
      return false;
    }

    if (username.isEmpty || fullName.isEmpty) {
      debugPrint("Lütfen tüm alanları doldurun");
      return false;
    }

    _setLoading(true);

    try {
      // ✅ GÜNCELLEME: AuthService.signUpWithEmail artık positional argüman bekliyor.
      // (email, password) şeklinde doğrudan gönderiyoruz.
      final result = await _authService.signUpWithEmail(
        email,
        password,
      );

      if (result != null && result.user != null) {
        // --- DATABASE GÜNCELLEMESİ ---
        await _authService.saveUserToDatabase(
          uid: result.user!.uid,
          fullName: fullName,
          username: username,
          email: email,
          phoneNumber: "", // Apple reddi sonrası telefon artık boş gönderiliyor
        );

        // Yerel hafıza güncellemeleri
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_p}user_type', 'free');
        await prefs.setString('${_p}full_name', fullName);

        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Kayıt hatası: $e");
    }

    _setLoading(false);
    return false;
  }

  // Eski metodlar (UI kırılmasın diye yönlendirildi)
  @Deprecated("Telefon doğrulaması kaldırıldı, signUp metodunu kullanın.")
  Future<bool> sendVerificationCode({required String email, required String phone}) async {
    return true;
  }

  @Deprecated("Telefon doğrulaması kaldırıldı, signUp metodunu kullanın.")
  Future<bool> completeSignUp({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String smsCode,
  }) async {
    return await signUp(
      fullName: fullName,
      username: username,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
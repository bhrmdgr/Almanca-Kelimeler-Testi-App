import 'package:almanca_kelime_testi/service/firebase/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Çakışmayı önlemek için SharedPreferences anahtarlarına eklenecek ön ek
  final String _p = "de_";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Email ile Giriş
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = "Lütfen tüm alanları doldurun.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    final result = await _authService.signInWithEmail(email, password);

    if (result == null) {
      _errorMessage = "Giriş başarısız. Lütfen bilgilerinizi kontrol edin.";
    } else {
      // Başarılı girişte kullanıcı tipini yerel hafızaya kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_p}user_type', 'free'); // Güncellendi
    }

    _setLoading(false);
    return result != null;
  }

  // Misafir Girişi
  Future<bool> loginAsGuest(String username) async {
    if (username.trim().isEmpty) return false;

    _setLoading(true);
    _errorMessage = null;

    final result = await _authService.signInAnonymously();

    if (result != null && result.user != null) {
      try {
        // 1. Sadece temel bilgileri Firestore'a kaydet (GuestUsers koleksiyonuna)
        await _authService.saveGuestToDatabase(
          uid: result.user!.uid,
          username: username,
        );

        // 2. Diğer tüm verileri Local olarak Shared Preferences'a kaydet
        await _initializeLocalGuestData(result.user!.uid, username);

        _setLoading(false);
        return true;
      } catch (e) {
        _errorMessage = "Veritabanına kaydedilirken bir hata oluştu: $e";
      }
    } else {
      _errorMessage = "Misafir girişi yapılamadı.";
    }

    _setLoading(false);
    return false;
  }

  // Local Verileri Başlatma (Shared Preferences)
  Future<void> _initializeLocalGuestData(String uid, String username) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('${_p}guest_uid', uid);
    await prefs.setString('${_p}guest_username', username);
    await prefs.setString('${_p}guest_level', 'A1');
    await prefs.setInt('${_p}guest_score', 0);
    await prefs.setBool('${_p}is_guest', true);
    await prefs.setString('${_p}user_type', 'guest'); // Güncellendi

    // Kelime listelerini JSON string olarak tutabiliriz
    await prefs.setStringList('${_p}guest_wrong_words', []);
    await prefs.setStringList('${_p}guest_learned_words', []);

    debugPrint("Misafir yerel verileri başarıyla oluşturuldu.");
  }


  // Parola sıfırlama

  Future<bool> resetPassword(String email) async {
    if (email.isEmpty || !email.contains("@")) {
      _errorMessage = "Lütfen geçerli bir e-posta adresi girin.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      // AuthService üzerinden şifre sıfırlama maili gönderiyoruz
      await _authService.sendPasswordResetEmail(email);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Şifre sıfırlama maili gönderilemedi: $e";
      _setLoading(false);
      return false;
    }
  }
}
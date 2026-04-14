import 'package:almanca_kelime_testi/service/firebase/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }


  // ProfileViewModel.dart içine eklenecek yeni metod:

  Future<bool> updateAvatar(String avatarPath) async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'avatarPath': avatarPath,
        });
        // Veriyi yerelde de güncellemek için tekrar çekiyoruz
        await fetchUserData();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Avatar güncellenemedi.";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserData() async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        _userData = doc.data();
      }
    } catch (e) {
      _errorMessage = "Veriler yüklenemedi.";
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserInfo(String field, String newValue) async {
    if (field == "fullName") {
      _errorMessage = "Ad Soyad bilgisi değiştirilemez.";
      return false;
    }
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({field: newValue});
        await fetchUserData();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Güncelleme başarısız.";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
        await _firestore.collection('users').doc(user.uid).update({'email': newEmail});
        await fetchUserData();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Güvenlik nedeniyle tekrar giriş yapmanız gerekebilir.";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
      _errorMessage = "Şifre güncellenemedi. Lütfen tekrar giriş yapın.";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // HESAP SİLME FONKSİYONU
  // ProfileViewModel.dart içindeki deleteAccount metodu

  // ProfileViewModel içindeki deleteAccount metodu

  // ProfileViewModel.dart içinde deleteAccount metodunu şu şekilde güncelle:

  Future<bool> deleteAccount(String currentPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _errorMessage = "Kullanıcı oturumu bulunamadı.";
        return false;
      }

      final uid = user.uid;

      // 1. ADIM: Yeniden Kimlik Doğrulama (Re-authentication)
      // "requires-recent-login" hatasını önlemek için şarttır.
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. ADIM: Firestore Verilerini Silme (Toplu İşlem - WriteBatch)
      // Önce verileri siliyoruz çünkü Auth silinirse yetkimiz biter.
      WriteBatch batch = _firestore.batch();

      // a) Ana kullanıcı dökümanını sil
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      batch.delete(userRef);

      // b) Leaderboard (Sıralama) dökümanını sil
      DocumentReference leaderboardRef = _firestore.collection('leaderboard').doc(uid);
      batch.delete(leaderboardRef);

      // Varsa diğer koleksiyonları (istatistikler vb.) buraya ekleyebilirsin:
      // DocumentReference statsRef = _firestore.collection('stats').doc(uid);
      // batch.delete(statsRef);

      // Tüm Firestore silme işlemlerini onayla
      await batch.commit();

      // 3. ADIM: Firebase Authentication kaydını sil
      await user.delete();

      // 4. ADIM: Yerel veriyi temizle
      _userData = null;

      debugPrint("Kullanıcı ve tüm verileri başarıyla silindi.");
      return true;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _errorMessage = "Girdiğiniz şifre hatalı.";
      } else if (e.code == 'requires-recent-login') {
        _errorMessage = "Güvenlik nedeniyle lütfen çıkış yapıp tekrar girerek deneyin.";
      } else {
        _errorMessage = "Auth Hatası: ${e.message}";
      }
      return false;
    } catch (e) {
      _errorMessage = "Beklenmedik bir hata oluştu: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendResetMail() async {
    if (_userData?['email'] == null) return false;
    try {
      await _authService.sendPasswordResetEmail(_userData!['email']);
      return true;
    } catch (e) {
      return false;
    }
  }
}
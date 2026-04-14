import 'package:almanca_kelime_testi/service/firebase/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı takip eden stream (Giriş yapılmış mı kontrolü için)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Email ve Şifre ile Kayıt Ol
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // 2. Email ve Şifre ile Giriş Yap
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // 3. Misafir Girişi (Anonim)
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // 4. Çıkış Yap
  Future<void> signOut() async {
    await NotificationService().deleteFcmToken();

    // ✅ EKLE: Yerel hafızadaki oturum tipini temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_type');
    // İsteğe bağlı: Misafirle ilgili diğer flagleri de silebilirsin
    // await prefs.clear(); // Tüm hafızayı boşaltmak en güvenlisidir

    await _auth.signOut();
  }

  // --- TELEFON DOĞRULAMA (APPLE REDDİ SONRASI DEVRE DIŞI BIRAKILDI) ---

  // 5. Telefon Numarasına Kod Gönder (Opsiyonel olarak durabilir ama çağrılmayacak)
  @Deprecated("Apple Guideline 5.1.1 uyarınca devre dışı bırakıldı.")
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint("FIREBASE AUTH HATASI: ${e.code} - ${e.message}");
        verificationFailed(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // 6. Telefon Kodu ve Email/Şifre ile Kaydı Tamamla (Artık kullanılmıyor)
  @Deprecated("Kayıt işlemi artık sadece signUpWithEmail üzerinden yapılacak.")
  Future<UserCredential?> signUpWithPhoneAndEmail({
    required String email,
    required String password,
    required String verificationId,
    required String smsCode,
  }) async {
    // Bu metodun işlevini doğrudan email kaydına yönlendiriyoruz
    return await signUpWithEmail(email, password);
  }

  // --- DATABASE GÜNCELLEMELERİ ---

  // 7. Normal Kullanıcı Verilerini 'users' Koleksiyonuna Kaydetme
  Future<void> saveUserToDatabase({
    required String uid,
    required String fullName,
    required String username,
    required String email,
    String? phoneNumber, // Artık null gelebilir
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber ?? '', // Null ise boş string ata
        'userType': 'free',
        'createdAt': FieldValue.serverTimestamp(),
        'level': 'A1',
        'score': 0,
        'isGuest': false,
        'daily_goal': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore Users Kayıt Hatası: $e");
      rethrow;
    }
  }

  Future<void> saveGuestToDatabase({
    required String uid,
    required String username,
  }) async {
    try {
      await _firestore.collection('guestUsers').doc(uid).set({
        'uid': uid,
        'username': username,
        'userType': 'guest',
        'createdAt': FieldValue.serverTimestamp(),
        'isGuest': true,
      });
    } catch (e) {
      debugPrint("Firestore GuestUsers Kayıt Hatası: $e");
      rethrow;
    }
  }

  // Firebase Hatalarını Yakalama
  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
        break;
      case 'wrong-password':
        message = "Hatalı şifre girdiniz.";
        break;
      case 'email-already-in-use':
        message = "Bu e-posta adresi zaten kullanımda.";
        break;
      case 'invalid-email':
        message = "Geçersiz bir e-posta adresi girdiniz.";
        break;
      case 'weak-password':
        message = "Şifre çok zayıf.";
        break;
      default:
        message = "Bir hata oluştu: ${e.message}";
    }
    debugPrint("AUTH ERROR: $message");
  }


  Future<void> updateUserAvatar(String uid, String avatarPath) async {
    await _firestore.collection('users').doc(uid).update({
      'avatarPath': avatarPath,
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 1. Bildirim İzni İste
  Future<void> requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Kullanıcı bildirim izni verdi.');
    } else {
      debugPrint('Kullanıcı bildirim izni vermedi.');
    }
  }

  // 2. Token Al ve Firestore'a Kaydet
  // ✅ Önce notifications_active kontrolü yapılıyor
  Future<void> updateFcmToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ Kullanıcının bildirim tercihini Firestore'dan kontrol et
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final notificationsActive = userDoc.data()?['notifications_active'] ?? true;

      if (!notificationsActive) {
        debugPrint("Bildirimler kapalı, FCM Token kaydedilmedi.");
        return; // ✅ Kapalıysa token kaydetme, çık
      }

      String? token = await _messaging.getToken();

      if (token != null) {
        await _firestore.collection('fcm_tokens').doc(user.uid).set({
          'token': token,
          'lastUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        }, SetOptions(merge: true));

        debugPrint("FCM Token Güncellendi: $token");
      }
    } catch (e) {
      debugPrint("FCM Token Kayıt Hatası: $e");
    }
  }

  // 3. Token Yenileme Dinleyicisi
  // ✅ Burada da notifications_active kontrolü yapılıyor
  void listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ Token yenilenince de bildirim durumu kontrol ediliyor
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final notificationsActive = userDoc.data()?['notifications_active'] ?? true;

      if (!notificationsActive) {
        debugPrint("Bildirimler kapalı, yenilenen token kaydedilmedi.");
        return;
      }

      await _firestore.collection('fcm_tokens').doc(user.uid).set({
        'token': newToken,
        'lastUpdate': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      }, SetOptions(merge: true));

      debugPrint("FCM Token Yenilendi: $newToken");
    });
  }

  // 4. Uygulama Açıkken Bildirim Göster (Foreground Handler)
  Future<void> initForegroundHandler() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground mesaj alındı: ${message.notification?.title}');
    });
  }

  // 5. Çıkışta Token Sil
  Future<void> deleteFcmToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _messaging.deleteToken();
      await _firestore.collection('fcm_tokens').doc(user.uid).delete();
      debugPrint("FCM Token silindi.");
    } catch (e) {
      debugPrint("FCM Token Silme Hatası: $e");
    }
  }
}
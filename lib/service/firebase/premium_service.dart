import 'dart:async';
import 'dart:io'; // ✅ Platform kontrolü için eklendi
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // ✅ Platforma özel ID tanımlamaları
  static const String _monthlyIdAndroid = 'almanca_premium_monthly';
  static const String _yearlyIdAndroid = 'almanca_premium_yearly';

  static const String _monthlyIdIOS = 'com.almanca.aylik';
  static const String _yearlyIdIOS = 'com.almanca.yillik';

  // ✅ Aktif platforma göre doğru ID'yi seçen getter'lar
  String get monthlyId => Platform.isIOS ? _monthlyIdIOS : _monthlyIdAndroid;
  String get yearlyId => Platform.isIOS ? _yearlyIdIOS : _yearlyIdAndroid;
  Set<String> get _kIds => {monthlyId, yearlyId};

  // ✅ GERÇEK FİYATLARI ÇEKME
  Future<Map<String, String>> fetchSubscriptionPrices() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) return {};

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("Ürünler bulunamadı: ${response.notFoundIDs}");
      }

      Map<String, String> prices = {};
      for (var product in response.productDetails) {
        if (product.id == monthlyId) {
          prices['monthly'] = product.price;
          prices['monthly_id'] = monthlyId;
        } else if (product.id == yearlyId) {
          prices['yearly'] = product.price;
          prices['yearly_id'] = yearlyId;
        }
      }
      return prices;
    } catch (e) {
      debugPrint("Fiyat çekme hatası: $e");
      return {};
    }
  }

  // ✅ GERÇEK SATIN ALMA
  Future<bool> purchaseSubscription(String productId) async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) return false;

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return false;

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
        applicationUserName: _auth.currentUser?.uid,
      );

      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("Satın alma başlatma hatası: $e");
      return false;
    }
  }

  // ✅ ÖDEME ONAYI SONRASI FIREBASE GÜNCELLEME
  Future<bool> handleSuccessfulPurchase(String productId) async {
    DateTime now = DateTime.now();
    // ✅ productId kontrolü getter üzerinden yapılıyor
    DateTime expiryDate = productId == monthlyId
        ? now.add(const Duration(days: 30))
        : now.add(const Duration(days: 365));

    return await _updateUserPremiumStatus(true, expiryDate);
  }

  // ✅ İPTAL ETME
  Future<bool> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isAutoRenew': false,
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("İptal hatası: $e");
      return false;
    }
  }

  // ✅ GÜNCELLENEN METOD: Firestore günceller
  Future<bool> _updateUserPremiumStatus(bool status, DateTime expiryDate) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isPremium': status,
          'premiumUntil': Timestamp.fromDate(expiryDate),
          'isAutoRenew': status,
          'lastUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.isIOS ? 'iOS' : 'Android',
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Firestore güncelleme hatası: $e");
      return false;
    }
  }
}
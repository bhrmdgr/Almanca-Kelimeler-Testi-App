import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // TEST MODU KONTROLÜ (Gerçek cihazda yayınlarken false yapmayı unutma!)
  static const bool _isTestMode = false;

  // PREMIUM KONTROLÜ
  static bool isPremiumUser = false;

  static InterstitialAd? _interstitialAd;

  // --- REKLAM BİRİM KİMLİKLERİ ---

  static String get bannerAdUnitIdHome {
    if (_isTestMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-2464210864134868/1624152674';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2464210864134868/4990715871'; // ✅ iOS Home Banner ID
    }
    return '';
  }

  static String get bannerAdUnitIdQuiz {
    if (_isTestMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-2464210864134868/7997989336';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2464210864134868/2916184470'; // ✅ iOS Quiz Banner ID
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (_isTestMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-2464210864134868/4536387902';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2464210864134868/2308712217'; // ✅ iOS Geçiş Reklamı ID
    }
    return '';
  }

  // SDK Başlatma
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Ekran genişliğine göre uyarlanabilir (adaptive) boyutu hesaplayan fonksiyon
  static Future<AdSize?> getAdaptiveSize(BuildContext context) async {
    final double width = MediaQuery.of(context).size.width;
    return await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate());
  }

  // Banner Reklam Oluşturma Fonksiyonu
  static BannerAd createBannerAd({
    required String adUnitId,
    required AdSize size,
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailed,
  }) {
    return BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailed,
      ),
    );
  }

  // Geçiş reklamını yükle
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint("Geçiş reklamı yüklendi.");
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          debugPrint("Geçiş reklamı yükleme hatası: $error");
        },
      ),
    );
  }

  // Geçiş reklamını göster
  static void showInterstitialAd() {
    if (isPremiumUser) return;

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // Kapandıktan sonra hemen yenisini hazırla
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    } else {
      // Reklam o an hazır değilse bile arka planda yükle ki bir sonrakine yetişsin
      debugPrint("Reklam henüz hazır değil, yükleme başlatıldı.");
      loadInterstitialAd();
    }
  }
}
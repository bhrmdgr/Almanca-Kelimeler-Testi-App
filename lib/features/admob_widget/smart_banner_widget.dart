import 'package:almanca_kelime_testi/service/admob/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SmartBannerWidget extends StatefulWidget {
  final String adUnitId;
  const SmartBannerWidget({super.key, required this.adUnitId});

  @override
  State<SmartBannerWidget> createState() => _SmartBannerWidgetState();
}

class _SmartBannerWidgetState extends State<SmartBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdSize? _adSize; // Dinamik boyut için

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Premium kontrolü ve reklamın daha önce yüklenip yüklenmediği kontrolü
    if (!AdMobService.isPremiumUser && _bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    // Ekran genişliğine uygun boyutu al
    final size = await AdMobService.getAdaptiveSize(context);
    if (size == null) return;

    setState(() {
      _adSize = size;
    });

    _bannerAd = AdMobService.createBannerAd(
      adUnitId: widget.adUnitId,
      size: size, // Hesaplanan boyut
      onAdLoaded: (ad) {
        if (mounted) setState(() => _isLoaded = true);
      },
      onAdFailed: (ad, error) {
        ad.dispose();
        debugPrint('Reklam yüklenemedi: $error');
      },
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdMobService.isPremiumUser || !_isLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white, // Alt boşluk rengi
      width: _adSize!.width.toDouble(),
      height: _adSize!.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
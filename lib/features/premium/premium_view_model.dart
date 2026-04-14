import 'dart:async';
import 'dart:io';
import 'package:almanca_kelime_testi/features/home/home_model.dart';
import 'package:almanca_kelime_testi/service/firebase/premium_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../service/admob/admob_service.dart';
import '../settings/settings_view_model.dart';

class PremiumViewModel extends ChangeNotifier {
  final PremiumService service = PremiumService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  SettingsViewModel? _settingsVM;

  bool isLoading = false;
  String monthlyPrice = "---";
  String yearlyPrice = "---";
  String selectedPlan = '';

  String? expiryDateText;
  bool isAutoRenew = true;
  bool isAlreadyPremium = AdMobService.isPremiumUser;

  PremiumViewModel() {
    initPrices();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void selectPlan(String plan) {
    if (isAlreadyPremium) return;
    selectedPlan = plan;
    debugPrint("LOG: Plan Seçildi -> $plan");
    notifyListeners();
  }

  void init(HomeModel? userData, SettingsViewModel settingsVM) {
    _settingsVM = settingsVM;
    debugPrint("LOG: ViewModel Başlatılıyor...");

    final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription?.cancel();
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      debugPrint("LOG: Satın Alma Stream'inden veri geldi! Liste uzunluğu: ${purchaseDetailsList.length}");
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      debugPrint("LOG: Satın Alma Stream'i kapandı.");
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint("LOG: Stream Hatası: $error");
      isLoading = false;
      notifyListeners();
    });

    if (userData != null) {
      isAlreadyPremium = userData.isPremium;
      isAutoRenew = userData.isAutoRenew;
      if (userData.premiumUntil != null) {
        final date = userData.premiumUntil!;
        expiryDateText = "${date.day} ${_getMonthName(date.month)} ${date.year}";
      }
      notifyListeners();
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint("LOG: İşlem Durumu: ${purchaseDetails.status} | Ürün: ${purchaseDetails.productID}");

      if (purchaseDetails.status == PurchaseStatus.pending) {
        // İşlem askıda (Ödeme bekleniyor)
        isLoading = true;
        notifyListeners();
      } else {
        // İşlem tamamlandı (Başarılı, Hata veya İptal)
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          debugPrint("LOG: Ödeme onaylandı. Veritabanı güncelleniyor...");

          // 1. Firebase/Backend güncellemesi
          bool success = await service.handleSuccessfulPurchase(purchaseDetails.productID);

          if (success) {
            debugPrint("LOG: Veritabanı başarıyla güncellendi. Kullanıcı Premium yapılıyor.");

            // 2. Uygulama içi lokal bayrakları güncelle
            AdMobService.isPremiumUser = true;
            isAlreadyPremium = true;

            // 3. SettingsViewModel'i haberdar et (UI'ın yenilenmesi için)
            _settingsVM?.markChanged();
          } else {
            debugPrint("LOG: Kritik Hata: Ödeme başarılı ama Firebase güncellenemedi!");
          }

          // 4. Apple/Google tarafına işlemin bittiğini bildir (Kritik: Bildirmezsen para iade edilir)
          if (purchaseDetails.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchaseDetails);
            debugPrint("LOG: StoreKit/PlayStore işlemi sonlandırıldı.");
          }
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("LOG: Satın alma hatası detay: ${purchaseDetails.error}");
          isLoading = false;
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint("LOG: Kullanıcı ödemeyi manuel olarak iptal etti.");
          isLoading = false;
        }

        // Her durumda yükleme ekranını kapat ve UI'ı güncelle
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> initPrices() async {
    debugPrint("LOG: Fiyatlar çekiliyor...");
    isLoading = true;
    notifyListeners();

    try {
      final prices = await service.fetchSubscriptionPrices();
      debugPrint("LOG: Store'dan dönen veriler: $prices");

      if (prices.isEmpty) {
        debugPrint("LOG: KRİTİK HATA: Ürün listesi BOŞ! Apple Store Connect ID'lerini kontrol edin.");
      }

      monthlyPrice = prices['monthly'] ?? "N/A";
      yearlyPrice = prices['yearly'] ?? "N/A";

      if(prices.containsKey('yearly_id')) {
        selectedPlan = prices['yearly_id']!;
        debugPrint("LOG: Varsayılan plan atandı: $selectedPlan");
      } else {
        selectedPlan = Platform.isIOS ? 'com.kelimeTesti.yillik' : 'premium_yearly';
        debugPrint("LOG: Varsayılan plan (Fallback) atandı: $selectedPlan");
      }
    } catch (e) {
      debugPrint("LOG: initPrices Catch: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startPurchase(BuildContext context, SettingsViewModel settingsVM) async {
    debugPrint("LOG: Satın alma düğmesine basıldı. Seçili plan: $selectedPlan");

    if (selectedPlan.isEmpty || monthlyPrice == "N/A") {
      debugPrint("LOG: HATA: Ürün hazır değil.");
      _showErrorSnackBar(context, "Ürün bilgileri yüklenemedi.");
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      debugPrint("LOG: In-App Purchase tetikleniyor...");
      bool pending = await service.purchaseSubscription(selectedPlan);
      debugPrint("LOG: Satın alma tetiklendi mi? -> $pending");

      if (!pending) {
        debugPrint("LOG: Satın alma tetiklenemedi (Pending false dönüyor).");
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint("LOG: startPurchase Catch: $e");
    }
  }

  String _getMonthName(int month) {
    const months = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
    return months[month - 1];
  }

  Future<void> manageSubscription() async {
    String url = "";
    if (Platform.isIOS) {
      // iOS için doğrudan abonelik yönetimi sayfası
      url = "https://apps.apple.com/account/subscriptions";
    } else {
      // Android için Play Store abonelikler sayfası
      // 'package_name' yerine kendi paket adını yazabilirsin (örn: com.kelimeTest.app)
      url = "https://play.google.com/store/account/subscriptions";
    }

    debugPrint("LOG: Abonelik yönetimi açılıyor: $url");
    await launchURL(url);
  }

  Future<void> cancelSubscription(BuildContext context, SettingsViewModel settingsVM) async {
    if (Platform.isIOS) {
      launchURL("https://apps.apple.com/account/subscriptions");
    } else {
      isLoading = true;
      notifyListeners();
      bool success = await service.cancelSubscription();
      isLoading = false;
      if (success) {
        isAutoRenew = false;
        settingsVM.markChanged();
        _showSuccessDialog(context, "Yenileme durduruldu.");
      }
    }
  }

  // PremiumViewModel.dart içinde launchURL metodunu güncelle:

  Future<void> launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      // Apple incelemesinde linklerin açıldığından emin olmak için mode'u kontrol et
      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
        debugPrint("Link açılamadı: $urlString");
      }
    } catch (e) {
      debugPrint("URL Hatası: $e");
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("İşlem Başarılı"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("TAMAM"))],
      ),
    );
  }

  Future<void> restorePurchases() async {
    debugPrint("LOG: Restore işlemi başlatıldı...");
    isLoading = true;
    notifyListeners();
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch(e) {
      debugPrint("LOG: Restore Catch: $e");
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        if(isLoading) {
          debugPrint("LOG: Restore zaman aşımına uğradı veya bitti.");
          isLoading = false;
          notifyListeners();
        }
      });
    }
  }

  void _showErrorSnackBar(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? "İşlem başarısız oldu.")));
  }
}
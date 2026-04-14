import 'dart:io';

import 'package:almanca_kelime_testi/features/auth/signIn/sign_in_view.dart';
import 'package:almanca_kelime_testi/features/auth/signIn/sign_in_view_model.dart';
import 'package:almanca_kelime_testi/features/auth/signUp/sign_up_view_model.dart';
import 'package:almanca_kelime_testi/features/help_support/help_view_model.dart';
import 'package:almanca_kelime_testi/features/home/home_view.dart';
import 'package:almanca_kelime_testi/features/home/home_view_model.dart';
import 'package:almanca_kelime_testi/features/premium/premium_view_model.dart';
import 'package:almanca_kelime_testi/features/profile/profile_view_model.dart';
import 'package:almanca_kelime_testi/features/quiz/quiz_view_model.dart';
import 'package:almanca_kelime_testi/features/settings/settings_view_model.dart';
import 'package:almanca_kelime_testi/firebase_options.dart';
import 'package:almanca_kelime_testi/helpers/routers/routers.dart';
import 'package:almanca_kelime_testi/helpers/theme/theme.dart';
import 'package:almanca_kelime_testi/service/admob/admob_service.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // ✅ kDebugMode için eklendi

// ✅ Background mesaj handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Arka planda mesaj alındı: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ APP CHECK: Token'ın otomatik yenilenmesini sağlar
  if (Platform.isIOS || Platform.isAndroid) {
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  }

  // ✅ APP CHECK AKTİVASYONU - GÜNCELLENMİŞ VE HATA GİDERİLMİŞ VERSİYON
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    // Android: Debug modda 'debug', market sürümünde 'playIntegrity'
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    // iOS: Debug modda 'debug', market sürümünde 'deviceCheck'
    // AppleProvider.debug sınıf yapısı kullanılarak tip hatası önlendi.
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  // ✅ ADMOB SDK BAŞLATILIYOR
  await AdMobService.initialize();

  // ✅ Background handler kayıt ediliyor
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignInViewModel()),
        ChangeNotifierProvider(create: (_) => SignUpViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => QuizViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => HelpViewModel()),
        ChangeNotifierProvider(create: (_) => PremiumViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'German Quiz',
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouters.generateRoute,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await Future.delayed(const Duration(seconds: 1));
      await AppTrackingTransparency.requestTrackingAuthorization();

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        if (user != null) {
          // ✅ Misafir (anonim) kullanıcılar için Firestore kontrolünü atla
          if (user.isAnonymous) {
            return const HomeView();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userDoc) {
              if (userDoc.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (!userDoc.hasData || !userDoc.data!.exists) {
                FirebaseAuth.instance.signOut();
                return const SigninView();
              }

              return const HomeView();
            },
          );
        }

        return const SigninView();
      },
    );
  }
}
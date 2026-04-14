import 'package:almanca_kelime_testi/features/auth/signIn/sign_in_view.dart';
import 'package:almanca_kelime_testi/features/auth/signUp/sign_up_view.dart';
import 'package:almanca_kelime_testi/features/help_support/help_view.dart';
import 'package:almanca_kelime_testi/features/home/home_model.dart';
import 'package:almanca_kelime_testi/features/home/home_view.dart';
import 'package:almanca_kelime_testi/features/leaderboard/leaderboard_view.dart';
import 'package:almanca_kelime_testi/features/leaderboard/leaderboard_view_model.dart';
import 'package:almanca_kelime_testi/features/premium/premium_view.dart';
import 'package:almanca_kelime_testi/features/profile/profile_view.dart';
import 'package:almanca_kelime_testi/features/quiz/quiz_model.dart';
import 'package:almanca_kelime_testi/features/quiz/quiz_options/quiz_options_view.dart';
import 'package:almanca_kelime_testi/features/quiz/quiz_screen/quiz_view.dart';
import 'package:almanca_kelime_testi/features/settings/settings_view.dart';
import 'package:almanca_kelime_testi/features/statistics/learned_words_view.dart';
import 'package:almanca_kelime_testi/features/statistics/wrong_words_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppRouters {
  static const String signIn = '/sign_in_view';
  static const String signUp = '/sign_up_view';
  static const String home = '/home_view';
  static const String settingsView = '/settings_view';
  static const String quizOptions = '/quiz_options_view';
  static const String quizView = '/quiz_view';
  static const String learnedWords = '/learned_words_view';
  static const String wrongWords = '/wrong_words_view';
  static const String profile = '/profile_view';
  static const String help = '/help_view';
  static const String premium = '/premium_view';
  static const String leaderboard = '/leaderboard_view';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signIn:
        return MaterialPageRoute(builder: (_) => const SigninView());
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignupView());
      case settingsView:
        return MaterialPageRoute(builder: (_) => const SettingsView());
      case quizOptions:
        return MaterialPageRoute(builder: (_) => const QuizOptionsView());

      case quizView:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => QuizView(
            quizList: args['quizList'] as List<WordModel>,
            isReviewMode: args['isReviewMode'] ?? false,
            isLearnedReview: args['isLearnedReview'] ?? false, // ✅ Burayı ekle
          ),
        );

      case learnedWords:
        return MaterialPageRoute(builder: (_) => const LearnedWordsView());
      case wrongWords:
        return MaterialPageRoute(builder: (_) => const WrongWordsView());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeView());
      case help:
        return MaterialPageRoute(builder: (_) => const HelpView());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileView());
      case premium:
        return MaterialPageRoute(builder: (_) => const PremiumView());

      case leaderboard:
      // HomeView'dan gönderdiğimiz userData'yı alıyoruz
        final args = settings.arguments as HomeModel;
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => LeaderboardViewModel(),
            child: LeaderboardView(userData: args),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route bulunamadı: ${settings.name}')),
          ),
        );
    }
  }
}
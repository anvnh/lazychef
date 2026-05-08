import 'package:flutter/material.dart';
import 'package:lazychef/features/auth/ui/login_screen.dart';
import 'package:lazychef/features/auth/ui/register_screen.dart';
import 'package:lazychef/features/history/ui/history_screen.dart';
import 'package:lazychef/features/home/ui/home_screen.dart';
import 'package:lazychef/features/recipe/ui/search_screen.dart';
import 'package:lazychef/features/scan/ui/scan_result_screen.dart';
import 'package:lazychef/features/recipe/ui/recipe_screen.dart';
import 'package:lazychef/features/recipe/ui/recipe_detail_screen.dart';
import 'package:lazychef/features/ingredients/ui/ingredients_screen.dart';
import 'package:lazychef/features/home/ui/user_profile_screen.dart';

class AppRouter {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String scanResult = '/scan-result';
  static const String history = '/history';
  static const String recipe = '/recipe';
  static const String ingredients = '/ingredients';
  static const String recipeDetail = '/recipe-detail';
  static const String userProfile = '/user-profile';
  static const String search = '/search';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case scanResult:
        return _buildRoute(const ScanResultScreen(), settings);
        case history:
        return _buildRoute(const HistoryScreen(), settings);
      case ingredients:
        return _buildRoute(const IngredientsScreen(), settings);
      case recipe:
        return _buildRoute(const RecipeScreen(), settings);
      case recipeDetail:
        return _buildRoute(const RecipeDetailScreen(), settings);
      case userProfile:
        return _buildRoute(const UserProfileScreen(), settings);
      case search:
        return _buildRoute(const SearchScreen(), settings);
      default:
        return _buildRoute(const LoginScreen(), settings);
    }
  }

  static PageRoute<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, _) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: page,
        );
      },
    );
  }
}

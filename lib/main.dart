import 'package:flutter/material.dart';
import 'package:lazychef/core/router/app_router.dart';
import 'package:lazychef/core/theme/app_theme.dart';

void main() {
  runApp(const LazyChefApp());
}

class LazyChefApp extends StatelessWidget {
  const LazyChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LazyChef',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRouter.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

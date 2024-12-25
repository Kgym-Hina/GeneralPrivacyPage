import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy/privacy_page.dart';
import 'package:privacy/remove_account_page.dart';

void main() {
  if (kIsWeb){
    usePathUrlStrategy();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PrivacyStatementPage(),
        ),
        GoRoute(
          path: '/remove',
          builder: (context, state) => const RemoveAccountPage(),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      title: '隐私政策',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text_windows/speech_to_text_windows.dart';

import 'features/auth/login_screen.dart';
import 'app/app_shell.dart';
import 'features/admin/admin_shell.dart';
import 'features/parent/parent_portal_screen.dart';
import 'features/auth/api_test_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.windows) {
    SpeechToTextWindows.registerWith();
  }

  runApp(const UniSphereApp());
}

class UniSphereApp extends StatelessWidget {
  const UniSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniSphere',
      theme: AppTheme.light,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/app': (context) => const AppShell(),
        '/student': (context) => const AppShell(),
        '/parent': (context) => const ParentPortalScreen(),
        '/admin': (context) => const AdminShell(),
        '/api-test': (context) => const ApiTestScreen(),
      },
    );
  }
}

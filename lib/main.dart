import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/contract_service.dart';

void main() {
  // Initialize contract service with dummy contracts
  ContractService.initializeDummyContracts();
  runApp(const MyJanjiApp());
}

class MyJanjiApp extends StatelessWidget {
  const MyJanjiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyJanji',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}

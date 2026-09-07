// PM CRM Mobile — точка входа.

import 'package:flutter/material.dart';

import 'src/screens/home_screen.dart';
import 'src/theme.dart';

void main() {
  runApp(const PmCrmApp());
}

class PmCrmApp extends StatelessWidget {
  const PmCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PM CRM',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}

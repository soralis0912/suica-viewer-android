import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SuicaViewerApp());
}

class SuicaViewerApp extends StatelessWidget {
  const SuicaViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suica Viewer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

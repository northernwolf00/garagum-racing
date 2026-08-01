import 'package:flutter/material.dart';

import 'screens/race_screen.dart';

void main() {
  runApp(const GaragumRacingApp());
}

class GaragumRacingApp extends StatelessWidget {
  const GaragumRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garagum Racing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8A33D)),
        useMaterial3: true,
      ),
      home: const RaceScreen(),
    );
  }
}

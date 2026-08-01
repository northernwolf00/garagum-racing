import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/menu/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait before the first frame is shown.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide system UI bars for a full-screen experience.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
      home: const MenuScreen(),
    );
  }
}

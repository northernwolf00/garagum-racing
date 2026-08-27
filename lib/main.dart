import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/menu/menu_screen.dart';
import 'services/ad_service.dart';
import 'services/game_progress_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved coins/round-progress before the first frame, so every screen
  // (menu coin badge, level unlock state) always reads real persisted data
  // instead of racing an unawaited init and silently writing nothing.
  await GameProgressService.instance.init();

  // Set up purchases first so ad-gating knows the no-ads/VIP entitlement
  // state, then initialise ads. Both degrade to safe no-ops if their
  // credentials aren't configured, so neither can block startup.
  await PurchaseService.instance.init();
  await AdService.instance.init();

  // Grant the VIP daily coin bonus once per day (no-op for non-VIP players).
  await GameProgressService.instance
      .claimVipDailyIfDue(PurchaseService.instance.isVip);

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

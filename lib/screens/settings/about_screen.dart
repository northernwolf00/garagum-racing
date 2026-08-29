import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'settings_screen.dart' show kSupportEmail;

/// "About Us" page — game blurb, developer and a friendly footer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _bg = Color(0xFF140A03);
  static const _amber = Color(0xFFE8A33D);
  static const _cream = Color(0xFFFFD98C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.7),
                  radius: 1.2,
                  colors: [Color(0xFF2A1608), _bg],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0x22E8A33D),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x44E8A33D)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: _cream, size: 22),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'about_us'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _cream,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      const SizedBox(height: 12),
                      // Logo badge
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8C1A), Color(0xFFE85A00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C1A).withValues(
                                    alpha: 0.35),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.sports_motorsports_rounded,
                              color: Colors.white, size: 52),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'GARAGUM RACING',
                          style: TextStyle(
                            color: _cream,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '${'version'.tr} 1.0.0',
                          style: const TextStyle(
                            color: Color(0xFF8A6A3F),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Blurb card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C0E06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x33E8A33D)),
                        ),
                        child: Text(
                          'about_us_body'.tr,
                          style: const TextStyle(
                            color: _cream,
                            fontSize: 14.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Developer row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C0E06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x33E8A33D)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.code_rounded,
                                color: _amber, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'developer'.tr,
                                style: const TextStyle(
                                  color: _cream,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'developer_name'.tr,
                              style: const TextStyle(
                                color: Color(0xFF8A6A3F),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact / support email (display only)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C0E06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x33E8A33D)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline_rounded,
                                color: _amber, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'contact_us'.tr,
                                    style: const TextStyle(
                                      color: _cream,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    kSupportEmail,
                                    style: TextStyle(
                                      color: Color(0xFF8A6A3F),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          'made_with_love'.tr,
                          style: const TextStyle(
                            color: Color(0xFF6E5533),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

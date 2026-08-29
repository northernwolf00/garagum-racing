import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../i18n/locale_service.dart';
import '../../i18n/translation_service.dart';
import '../../services/app_settings.dart';
import '../../services/purchase_service.dart';
import 'about_screen.dart';

/// Full-screen, modern settings page (replaces the old bottom sheet).
///
/// Grouped into cards — Audio, Language, Purchases and About — over the same
/// warm desert palette used across the game.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _bg = Color(0xFF140A03);
  static const _amber = Color(0xFFE8A33D);
  static const _cream = Color(0xFFFFD98C);

  void _applyMusic(bool on) {
    AppSettings.instance.setMusic(on);
    if (on) {
      FlameAudio.bgm.play('music/menu_theme.ogg', volume: 0.45);
    } else {
      FlameAudio.bgm.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Soft radial glow so the flat background feels less empty.
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
                _Header(title: 'settings'.tr),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // ── Audio ─────────────────────────────────────────────
                      _SectionCard(
                        title: 'audio'.tr,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: AppSettings.instance.music,
                            builder: (_, on, __) => _SwitchTile(
                              icon: Icons.music_note_rounded,
                              label: 'music'.tr,
                              value: on,
                              onChanged: _applyMusic,
                            ),
                          ),
                          const _TileDivider(),
                          ValueListenableBuilder<bool>(
                            valueListenable: AppSettings.instance.sfx,
                            builder: (_, on, __) => _SwitchTile(
                              icon: Icons.graphic_eq_rounded,
                              label: 'sound_effects'.tr,
                              value: on,
                              onChanged: AppSettings.instance.setSfx,
                            ),
                          ),
                        ],
                      ),

                      // ── Language ──────────────────────────────────────────
                      _SectionCard(
                        title: 'language'.tr,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                            child: Text(
                              'choose_language'.tr,
                              style: const TextStyle(
                                color: Color(0xFF8A6A3F),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _LanguageList(onChanged: () => setState(() {})),
                        ],
                      ),

                      // ── Purchases ─────────────────────────────────────────
                      _SectionCard(
                        title: 'purchases_section'.tr,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable:
                                PurchaseService.instance.noAdsNotifier,
                            builder: (context, noAds, _) {
                              final adFree =
                                  noAds || PurchaseService.instance.isVip;
                              if (adFree) {
                                return _InfoTile(
                                  icon: Icons.verified_rounded,
                                  label: 'ad_free_active'.tr,
                                  color: const Color(0xFF76FF03),
                                );
                              }
                              return _NavTile(
                                icon: Icons.block_rounded,
                                label: 'remove_ads'.tr,
                                onTap: () => PurchaseService.instance
                                    .presentPaywallIfNeeded(
                                  PurchaseService.entitlementNoAds,
                                ),
                              );
                            },
                          ),
                          const _TileDivider(),
                          _NavTile(
                            icon: Icons.restore_rounded,
                            label: 'restore_purchases'.tr,
                            onTap: () async {
                              final ok = await PurchaseService.instance
                                  .restorePurchases();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'purchases_restored'.tr
                                      : 'restore_failed'.tr),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // ── About ─────────────────────────────────────────────
                      _SectionCard(
                        title: 'about'.tr,
                        children: [
                          _NavTile(
                            icon: Icons.info_outline_rounded,
                            label: 'about_us'.tr,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AboutScreen(),
                              ),
                            ),
                          ),
                          const _TileDivider(),
                          _NavTile(
                            icon: Icons.star_rounded,
                            label: 'rate_us'.tr,
                            onTap: () => _comingSoon(context),
                          ),
                          const _TileDivider(),
                          _NavTile(
                            icon: Icons.share_rounded,
                            label: 'share_app'.tr,
                            onTap: () => _comingSoon(context),
                          ),
                          const _TileDivider(),
                          _NavTile(
                            icon: Icons.privacy_tip_outlined,
                            label: 'privacy_policy'.tr,
                            onTap: () => _comingSoon(context),
                          ),
                          const _TileDivider(),
                          _InfoTile(
                            icon: Icons.tag_rounded,
                            label: 'version'.tr,
                            trailing: 'v1.0.0',
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'made_with_love'.tr,
                          style: const TextStyle(
                            color: Color(0xFF6E5533),
                            fontSize: 12,
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

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('coming_soon'.tr),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Back button + centered screen title, shared by settings/about pages.
class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _SettingsScreenState._cream,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0x22E8A33D),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x44E8A33D)),
        ),
        child: Icon(icon,
            color: _SettingsScreenState._cream, size: 22),
      ),
    );
  }
}

/// A titled card grouping related setting rows.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: _SettingsScreenState._amber,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C0E06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33E8A33D)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Divider(color: Color(0x1AE8A33D), height: 1),
      );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _SettingsScreenState._amber, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _SettingsScreenState._cream,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFFF8C1A),
            inactiveTrackColor: const Color(0x22FFFFFF),
            inactiveThumbColor: const Color(0xFF8A6A3F),
          ),
        ],
      ),
    );
  }
}

/// A tappable row with a leading icon and a trailing chevron.
class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: _SettingsScreenState._amber, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _SettingsScreenState._cream,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF8A6A3F), size: 22),
          ],
        ),
      ),
    );
  }
}

/// A non-tappable row that shows a value or status (e.g. version, ad-free).
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _SettingsScreenState._cream;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: color ?? _SettingsScreenState._amber, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: Color(0xFF8A6A3F),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// Modern language selector: one full-width row per language with a flag,
/// native name and a check on the active one.
class _LanguageList extends StatelessWidget {
  const _LanguageList({required this.onChanged});
  final VoidCallback onChanged;

  static const _flags = ['🇬🇧', '🇷🇺', '🇹🇲'];

  @override
  Widget build(BuildContext context) {
    final current = LocaleService.instance.currentCode;
    final codes =
        TranslationService.locales.map((l) => l.languageCode).toList();

    return Column(
      children: [
        for (int i = 0; i < codes.length; i++) ...[
          if (i > 0) const _TileDivider(),
          InkWell(
            onTap: () async {
              if (codes[i] != current) {
                await LocaleService.instance.setLanguage(codes[i]);
                onChanged();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Text(_flags[i], style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      TranslationService.langs[i],
                      style: TextStyle(
                        color: codes[i] == current
                            ? Colors.white
                            : _SettingsScreenState._cream,
                        fontSize: 15.5,
                        fontWeight: codes[i] == current
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (codes[i] == current)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8C1A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                    )
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

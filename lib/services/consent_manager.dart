import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles Google UMP (User Messaging Platform) consent collection.
///
/// Must be called **before** [MobileAds.instance.initialize()].
/// Usage in main():
///   await ConsentManager.instance.gatherConsent();
///   if (await ConsentManager.instance.canRequestAds()) {
///     await MobileAds.instance.initialize();
///   }
///
/// For testing from a non-EEA region (e.g. Turkmenistan), enable
/// [_debugEea] and add your hashed device ID from logcat:
///   Use ConsentDebugSettings.Builder().addTestDeviceHashedId("XXXX...")
/// Then set [_debugEea] = true and put your ID in [_debugDeviceId].
/// IMPORTANT: Remove debug settings before releasing to production.
class ConsentManager {
  static ConsentManager? _instance;
  static ConsentManager get instance {
    _instance ??= ConsentManager._();
    return _instance!;
  }

  ConsentManager._();

  // ── Debug / testing settings ─────────────────────────────────────────────
  // Set to true and fill in your logcat device ID to simulate EEA geography
  // on a device located outside the EEA (e.g. in Turkmenistan).
  // MUST be false / removed before a production release.
  static const bool _debugEea = false;
  static const String _debugDeviceId = 'YOUR_HASHED_DEVICE_ID_FROM_LOGCAT';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Requests consent info and, if needed, shows the UMP consent form.
  ///
  /// Always awaits completion before returning so callers can rely on the
  /// consent state being settled (either granted, denied, or not required).
  /// Safe to call on every cold start — the SDK only shows the form when
  /// the user's consent is genuinely required or has expired.
  Future<void> gatherConsent() async {
    final params = _buildParams();
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Info updated successfully — show the form if needed.
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) {
            debugPrint('[consent] form error: \${error.message}');
          }
          if (!completer.isCompleted) completer.complete();
        });
      },
      (FormError error) {
        // Failed to fetch consent info (e.g. no network). The app still runs;
        // ads will only be requested if canRequestAds() returns true.
        debugPrint('[consent] info update failed: \${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  /// Returns true when it is safe to request and display ads.
  ///
  /// Will be false in regions where consent is required but has not yet been
  /// given, or where the consent form has not been shown yet.
  Future<bool> canRequestAds() async {
    return ConsentInformation.instance.canRequestAds();
  }

  /// Shows the "Privacy options" form so users can change their consent
  /// choices at any time. Required by Google policy when
  /// [PrivacyOptionsRequirementStatus.required] is true.
  ///
  /// Bind this to a button in your Settings screen.
  Future<void> showPrivacyOptionsForm() async {
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint('[consent] privacy options form error: \${error.message}');
      }
    });
  }

  /// Returns whether the "Privacy options" button must be shown to the user.
  ///
  /// In non-EEA regions (e.g. Turkmenistan) this will be [false], so the
  /// button is hidden. In EEA/UK regions it will be [true].
  Future<bool> isPrivacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Resets all stored consent state. Only for use during testing.
  /// Call this before each test run to force the form to appear again.
  /// NEVER call in production code.
  void resetForTesting() {
    assert(kDebugMode, 'resetForTesting() must only be called in debug mode');
    ConsentInformation.instance.reset();
    debugPrint('[consent] consent state reset for testing');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  ConsentRequestParameters _buildParams() {
    // In debug mode with _debugEea enabled, simulate EEA geography so the
    // consent form appears on devices outside the EEA.
    if (kDebugMode && _debugEea) {
      return ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
          testIdentifiers: [_debugDeviceId],
        ),
      );
    }
    // Production: let the SDK detect the user's real geography automatically.
    return ConsentRequestParameters();
  }
}

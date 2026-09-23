import 'package:flutter/services.dart';
import 'seo_data.dart';
import 'seo_dom_stub.dart'
    if (dart.library.html) 'seo_dom_web.dart';

/// Helper to apply SEO data cross-platform.
/// Updates the Flutter application title and browser DOM on Web.
class SeoHelper {
  static void apply(SeoData data) {
    // Cross-platform app switcher title
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(label: data.title),
    );

    // Apply to browser DOM (no-op on non-web)
    applySeoToDom(data);
  }
}

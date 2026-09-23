// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'seo_data.dart';

/// Web implementation that applies SEO metadata directly into the HTML `<head>`.
void applySeoToDom(SeoData data) {
  try {
    // 1. Document title
    html.document.title = data.title;

    // 2. Meta description
    _setMeta('description', data.description);

    // 3. Robots (noindex/nofollow for private routes, index/follow for public)
    _setMeta('robots', data.noIndex ? 'noindex, nofollow' : 'index, follow');

    // 4. Canonical URL
    if (data.canonicalUrl != null && data.canonicalUrl!.isNotEmpty) {
      _setCanonical(data.canonicalUrl!);
    }

    // 5. OpenGraph Tags
    _setOgMeta('og:title', data.title);
    _setOgMeta('og:description', data.description);
    _setOgMeta('og:type', data.ogType);
    if (data.canonicalUrl != null && data.canonicalUrl!.isNotEmpty) {
      _setOgMeta('og:url', data.canonicalUrl!);
    }
    if (data.ogImage != null && data.ogImage!.isNotEmpty) {
      _setOgMeta('og:image', data.ogImage!);
    } else {
      _removeOgMeta('og:image');
    }

    // 6. JSON-LD structured data
    _setJsonLd(data.jsonLd);
  } catch (_) {
    // Silent catch prevents any DOM update error from interrupting the Flutter app
  }
}

void _setMeta(String name, String content) {
  var element = html.document.querySelector('meta[name="$name"]');
  if (element == null) {
    element = html.MetaElement()..name = name;
    html.document.head?.append(element);
  }
  element.setAttribute('content', content);
}

void _setOgMeta(String property, String content) {
  var element = html.document.querySelector('meta[property="$property"]');
  if (element == null) {
    element = html.MetaElement()..setAttribute('property', property);
    html.document.head?.append(element);
  }
  element.setAttribute('content', content);
}

void _removeOgMeta(String property) {
  final element = html.document.querySelector('meta[property="$property"]');
  element?.remove();
}

void _setCanonical(String url) {
  var element = html.document.querySelector('link[rel="canonical"]');
  if (element == null) {
    element = html.LinkElement()..rel = 'canonical';
    html.document.head?.append(element);
  }
  element.setAttribute('href', url);
}

void _setJsonLd(Map<String, dynamic>? jsonLd) {
  const scriptId = 'edumarket-jsonld';
  final existing = html.document.getElementById(scriptId);
  if (jsonLd == null || jsonLd.isEmpty) {
    existing?.remove();
    return;
  }
  final script = existing ?? (html.ScriptElement()..id = scriptId..type = 'application/ld+json');
  script.text = jsonEncode(jsonLd);
  if (existing == null) {
    html.document.head?.append(script);
  }
}

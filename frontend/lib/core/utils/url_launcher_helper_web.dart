// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
library;

import 'dart:html' as html;

typedef UrlRedirectHandler = void Function(String url);

UrlRedirectHandler? _customRedirectHandler;

void setCustomRedirectHandler(UrlRedirectHandler? handler) {
  _customRedirectHandler = handler;
}

UrlRedirectHandler? getCustomRedirectHandler() => _customRedirectHandler;

void redirectToUrl(String url) {
  if (_customRedirectHandler != null) {
    _customRedirectHandler!(url);
    return;
  }
  html.window.location.href = url;
}

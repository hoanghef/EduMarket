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
  // No-op in stub (for non-web / widget testing environments)
}

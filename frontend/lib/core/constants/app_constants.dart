/// Application-wide constants.
library;

class AppConstants {
  AppConstants._();

  // ── API ───────────────────────────────────────────────────────────────────
  /// Backend base URL.  Override via --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  // ── Routing ───────────────────────────────────────────────────────────────
  static const String routeHome = '/';
  static const String routeCourses = '/khoa-hoc';
  static const String routeCourseDetail = '/khoa-hoc/:slug';
  static const String routeCategory = '/danh-muc/:slug';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeCart = '/cart';
  static const String routeCheckout = '/checkout';
  static const String routeAccount = '/account';
  static const String routeOrders = '/account/orders';
  static const String routeWishlist = '/wishlist';
  static const String routeLibrary = '/library';
  static const String routeCertificates = '/certificates';
  static const String routeAdmin = '/admin';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 12;

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

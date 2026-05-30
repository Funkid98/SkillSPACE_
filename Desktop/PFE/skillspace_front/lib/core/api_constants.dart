/// Central API configuration for SkillSpace Flutter Web.
///
/// The app is served by Nginx on port 80, which proxies:
///   /api/*          → api-gateway:8080
///   /recruiter/*    → api-gateway:8080
///   /candidat/*     → api-gateway:8080
///   /offers/*       → api-gateway:8080
///   /formateur/*    → api-gateway:8080
///   /interview/*    → api-gateway:8080
///
/// Using an empty baseUrl means all HTTP calls use *relative* URLs
/// (e.g. `/api/auth/login`) which are resolved against the page origin.
/// This works correctly in every environment:
///   • Local dev  : http://localhost:80  (Nginx on port 80)
///   • Docker     : http://<host>:80     (same Nginx)
///   • Production : https://yourdomain.com
///
/// ⚠️  Never hardcode `localhost:8088` here — that port is the raw
///     Express gateway and is NOT accessible from browsers in Docker.
class ApiConstants {
  ApiConstants._();

  /// Base URL for all API requests. Empty = relative to current origin (Nginx).
  static const String baseUrl = '';
}

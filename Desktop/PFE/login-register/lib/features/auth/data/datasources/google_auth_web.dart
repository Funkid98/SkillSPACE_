// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _clientId =
    '1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com';
String get _redirectUri => html.window.location.origin;

/// Redirects the current browser tab to Google's OAuth consent page.
/// After the user signs in, Google redirects back to [_redirectUri]
/// with the access token in the URL fragment (#access_token=...).
void startGoogleRedirectFlow(String role) {
  html.window.sessionStorage['pending_google_role'] = role;

  final url = Uri(
    scheme: 'https',
    host: 'accounts.google.com',
    path: '/o/oauth2/v2/auth',
    queryParameters: {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'token',
      'scope': 'email profile',
      'include_granted_scopes': 'true',
      'prompt': 'select_account',
    },
  ).toString();

  html.window.location.href = url;
}

/// Returns true if the URL fragment contains an access_token.
bool hasGoogleRedirectToken() {
  final uri = Uri.parse(html.window.location.href);
  final fragment = Uri.splitQueryString(uri.fragment);
  return fragment.containsKey('access_token');
}

/// Call this on app startup. If the URL contains an access_token fragment
/// (i.e. we just returned from a Google OAuth redirect), extracts and returns
/// the token then clears the URL.
String? consumeOAuthToken() {
  final uri = Uri.parse(html.window.location.href);
  final fragment = Uri.splitQueryString(uri.fragment);
  final token = fragment['access_token'];
  if (token != null) {
    // Clean the token out of the address bar
    html.window.history
        .replaceState(null, '', html.window.location.pathname ?? '/');
  }
  return token;
}

/// Returns the role that was saved before the redirect, then clears it.
String? consumePendingRole() {
  final role = html.window.sessionStorage['pending_google_role'];
  html.window.sessionStorage.remove('pending_google_role');
  return role;
}

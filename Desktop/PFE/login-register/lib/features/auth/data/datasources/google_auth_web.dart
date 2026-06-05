// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

const _clientId =
    '1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com';

/// Redirect URI must match exactly what is registered in Google Cloud Console.
/// We use the app origin (e.g. http://localhost:3000) so the popup returns here.
String get _redirectUri => html.window.location.origin;

// ─── Popup-based OAuth flow ────────────────────────────────────────────────

/// Opens Google's OAuth consent page in a small popup window.
/// Returns the access token when the user completes sign-in, or throws.
///
/// The popup is redirected by Google back to [_redirectUri] which loads the
/// Flutter app again. On that load, [_isPopupCallback()] returns true and the
/// popup sends its token to the opener via postMessage then closes itself.
///
/// Replaces the old full-page redirect approach which killed the debugger.
Future<String> startGooglePopupFlow(String role) {
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

  // Open a centred 500×620 popup
  final screenW = html.window.screen?.width ?? 1024;
  final screenH = html.window.screen?.height ?? 768;
  final left = ((screenW - 500) / 2).round();
  final top = ((screenH - 620) / 2).round();

  final popup = html.window.open(
    url,
    '_google_signin_popup',
    'width=500,height=620,left=$left,top=$top,toolbar=no,menubar=no',
  );

  final completer = Completer<String>();

  // Listen for the token via BroadcastChannel (works even when COOP blocks window.opener)
  html.BroadcastChannel? broadcastChannel;
  try {
    broadcastChannel = html.BroadcastChannel('google_oauth_token');
    broadcastChannel.onMessage.listen((html.MessageEvent msg) {
      final data = msg.data;
      if (data is Map && data.containsKey('google_access_token')) {
        if (!completer.isCompleted) {
          completer.complete(data['google_access_token'] as String);
        }
        broadcastChannel?.close();
      }
    });
  } catch (_) {}

  // Also listen via postMessage as fallback
  late html.EventListener messageListener;
  messageListener = (html.Event event) {
    final msg = event as html.MessageEvent;
    if (msg.origin != html.window.location.origin) return;
    final data = msg.data;
    if (data is Map && data.containsKey('google_access_token')) {
      html.window.removeEventListener('message', messageListener);
      if (!completer.isCompleted) {
        completer.complete(data['google_access_token'] as String);
      }
      broadcastChannel?.close();
    } else if (data is Map && data.containsKey('google_error')) {
      html.window.removeEventListener('message', messageListener);
      if (!completer.isCompleted) {
        completer.completeError(Exception(data['google_error']));
      }
      broadcastChannel?.close();
    }
  };
  html.window.addEventListener('message', messageListener);

  // Detect if the popup was closed without completing
  // (guarded with try/catch because COOP may block access to popup.closed)
  Timer.periodic(const Duration(milliseconds: 500), (timer) {
    try {
      if (popup.closed == true) {
        timer.cancel();
        if (!completer.isCompleted) {
          html.window.removeEventListener('message', messageListener);
          broadcastChannel?.close();
          completer.completeError(Exception('popup_closed'));
        }
      }
    } catch (_) {
      // COOP blocked access — cannot detect popup close, keep waiting
    }
  });

  return completer.future;
}

/// Call this at app startup (before building any widget).
/// If we are running inside the OAuth popup callback (Google redirected
/// here with a token in the URL fragment), we extract the token, post it
/// to the opener, and close the popup — all without rendering anything.
///
/// Returns true if this run was a popup callback (caller should stop).
bool handlePopupCallback() {
  final uri = Uri.parse(html.window.location.href);
  final fragment = Uri.splitQueryString(uri.fragment);
  final token = fragment['access_token'];

  if (token == null) return false;

  // Clean the URL so the opener's replaceState isn't confused
  html.window.history
      .replaceState(null, '', html.window.location.pathname ?? '/');

  // Send token to the main window via BroadcastChannel (reliable even when
  // COOP severs window.opener) and also try postMessage as fallback.
  try {
    final channel = html.BroadcastChannel('google_oauth_token');
    channel.postMessage({'google_access_token': token});
    channel.close();
  } catch (_) {}

  // Fallback: try window.opener.postMessage (works when COOP doesn't block)
  try {
    html.window.opener?.postMessage(
      {'google_access_token': token},
      html.window.location.origin,
    );
  } catch (_) {}

  html.window.close();
  return true;
}

// ─── Legacy helpers kept for compatibility ──────────────────────────────────

/// @deprecated Use [startGooglePopupFlow] instead.
/// Kept so existing call-sites compile without changes.
void startGoogleRedirectFlow(String role) {
  // No-op — replaced by popup flow. Call startGooglePopupFlow() directly.
}

/// Returns true if the URL fragment contains an access_token.
bool hasGoogleRedirectToken() {
  final uri = Uri.parse(html.window.location.href);
  final fragment = Uri.splitQueryString(uri.fragment);
  return fragment.containsKey('access_token');
}

/// Extracts and removes the access_token from the URL fragment (legacy).
String? consumeOAuthToken() {
  final uri = Uri.parse(html.window.location.href);
  final fragment = Uri.splitQueryString(uri.fragment);
  final token = fragment['access_token'];
  if (token != null) {
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

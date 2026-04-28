/// Stub implementation for non-web platforms.
/// All methods are no-ops or return null.
void startGoogleRedirectFlow(String role) {}
String? consumeOAuthToken() => null;
String? consumePendingRole() => null;
bool hasGoogleRedirectToken() => false;

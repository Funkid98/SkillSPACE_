# 🍪 Cookie Management in SkillSpace

With the recent migration away from `shared_preferences`, the SkillSpace platform now relies entirely on a modern, web-first cookie architecture. This note documents how cookies are used across both the Flutter frontend and the Express backend.

## 1. The Two Types of Cookies

The platform now strictly separates **secure authentication state** from **non-sensitive client state**.

| Concept | Managed By | Access | Purpose |
| :--- | :--- | :--- | :--- |
| **Auth JWT (`skillspace_token`)** | Backend (Express) | `HttpOnly` (Invisible to JS/Dart) | Secure session authentication. Sent automatically by the browser to the backend on every API request. |
| **Client State (e.g. `user_data`)** | Frontend (`CookieService`) | `document.cookie` (Accessible to JS/Dart) | Storing non-sensitive UI state, cached user profiles, theme preferences, and local data. |

> [!CAUTION]
> **Never store sensitive data (like tokens or passwords) using `CookieService`.** The `CookieService` writes cookies that are accessible via Javascript, which makes them vulnerable to XSS attacks. Secure tokens must *always* be set by the backend using the `HttpOnly` flag.

---

## 2. The `CookieService` Utility

The `CookieService` is a custom Dart utility located in the `login-register` core package (`lib/core/network/cookie_service.dart`). It acts as a direct, drop-in replacement for `SharedPreferences`, but is optimized specifically for Flutter Web by reading/writing to `dart:html` `document.cookie`.

### Available Methods

The service exposes synchronous static methods that mirror the familiar `SharedPreferences` API:

```dart
// ── Strings ───────────────────────────────────────────────────
CookieService.setString('key', 'value');
String? value = CookieService.getString('key');

// ── Integers ──────────────────────────────────────────────────
CookieService.setInt('active_tab_index', 2);
int? index = CookieService.getInt('active_tab_index');

// ── Booleans ──────────────────────────────────────────────────
CookieService.setBool('is_dark_mode', true);
bool? isDark = CookieService.getBool('is_dark_mode');

// ── Lists of Strings ──────────────────────────────────────────
CookieService.setStringList('saved_candidates', ['id1', 'id2']);
List<String>? candidates = CookieService.getStringList('saved_candidates');

// ── Deletion ──────────────────────────────────────────────────
CookieService.remove('key');
CookieService.clear(); // Removes all non-HttpOnly cookies
```

### Expiration
By default, all data stored via `CookieService` is given a `max-age` of **30 days** (`2592000` seconds). This ensures UI state persists across browser restarts.

---

## 3. How to Work with APIs (`ApiClient`)

Because the JWT is now an `HttpOnly` cookie, you **do not need to manually attach tokens** to your API requests.

The `ApiClient` (`login-register/lib/core/network/api_client.dart`) uses the `http` package's `BrowserClient` with `withCredentials = true`. This instructs the browser to automatically attach the `skillspace_token` cookie to every request going to your Express backend.

**What this means for Flutter Developers:**
- You no longer need to read `jwt_token` from storage before making an API call.
- The `Authorization: Bearer <token>` header is completely removed from the frontend.
- When the user logs out, you must make a `POST` request to `/api/auth/logout` so the backend can issue a `Set-Cookie` command to delete the secure token.

## 4. Current Usage in the Monorepo

The `CookieService` is currently utilized across the monorepo to handle:

- **`user_data`**: A JSON string containing the logged-in user's profile (FirstName, LastName, Email, Role) to quickly render the UI on startup without waiting for an API call.
- **`active_tab_index`** / **`trainer_active_index`** / **`recruiter_active_tab`**: Remembers which navigation tab the user was looking at if they refresh the page.
- **`is_dark`**: Remembers the user's dark/light mode preference.
- **`saved_candidates`**: A local list of Candidate IDs that a recruiter has favorited/saved locally.

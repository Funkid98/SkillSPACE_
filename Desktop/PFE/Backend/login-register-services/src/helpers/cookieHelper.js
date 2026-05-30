const IS_PROD = process.env.NODE_ENV === "production";

const COOKIE_NAME = "skillspace_token";

const COOKIE_OPTIONS = {
  httpOnly: true,
  secure: IS_PROD, // ← HTTPS-only in production
  sameSite: IS_PROD ? "none" : "lax", // ← 'none' required for cross-origin HTTPS
  maxAge: 30 * 24 * 60 * 60 * 1000, // ← 30 days (ms)
  path: "/",
};

/**
 * Attach the JWT as a secure HttpOnly cookie.
 * @param {import('express').Response} res
 * @param {string} token  – signed JWT
 */
const setAuthCookie = (res, token) => {
  res.cookie(COOKIE_NAME, token, COOKIE_OPTIONS);
};

/**
 * Clear the auth cookie (logout).
 * @param {import('express').Response} res
 */
const clearAuthCookie = (res) => {
  res.clearCookie(COOKIE_NAME, {
    httpOnly: true,
    secure: IS_PROD,
    sameSite: IS_PROD ? "none" : "lax",
    path: "/",
  });
};

module.exports = { setAuthCookie, clearAuthCookie, COOKIE_NAME };

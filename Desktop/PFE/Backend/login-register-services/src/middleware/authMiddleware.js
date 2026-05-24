/**
 * authMiddleware.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Reads the JWT from the HttpOnly cookie first, then falls back to the
 * Authorization: Bearer <token> header for backwards-compatibility with
 * service-to-service calls (candidat-service, recruiter-service, etc.).
 *
 * Priority:
 *   1. req.cookies.skillspace_token  ← browser-managed HttpOnly cookie
 *   2. Authorization: Bearer <token> ← manual header (server-to-server / legacy)
 */

const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { COOKIE_NAME } = require('../helpers/cookieHelper');

exports.protect = async (req, res, next) => {
  try {
    let token;

    // 1. Prefer the secure HttpOnly cookie (set by /login, /google, /github)
    if (req.cookies && req.cookies[COOKIE_NAME]) {
      token = req.cookies[COOKIE_NAME];
    }

    // 2. Fallback: Authorization header (server-to-server, Postman, legacy clients)
    if (!token && req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer ')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Non autorisé. Veuillez vous connecter.',
      });
    }

    // Verify & decode
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = await User.findById(decoded.id).select('-password');

    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Utilisateur non trouvé.',
      });
    }

    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Token invalide ou expiré. Veuillez vous reconnecter.',
    });
  }
};
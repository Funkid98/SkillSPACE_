const jwt = require("jsonwebtoken");
const User = require("../models/User");
const {
  sendOtpEmail,
  sendLoginSuccessEmail,
  sendVerificationEmail,
} = require("../services/emailService");
const { OAuth2Client } = require("google-auth-library");
const axios = require("axios");
const { setAuthCookie, clearAuthCookie } = require("../helpers/cookieHelper");

const client = new OAuth2Client(
  "1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com",
);

const RECRUITER_SERVICE_URL = (process.env.INTERNAL_GATEWAY_URL || "http://127.0.0.1:8088") + "/recruiter";
const TRAINER_SERVICE_URL = (process.env.INTERNAL_GATEWAY_URL || "http://127.0.0.1:8088") + "/api/formateur";

// ── Internal helpers ──────────────────────────────────────────────────────────

const createTrainerProfile = async (userId, data) => {
  try {
    if (!data.password) {
      data.password = Math.random().toString(36).slice(-10);
    }
    await axios.put(
      `${TRAINER_SERVICE_URL}/profile/${userId}`,
      data,
    );
  } catch (error) {
    console.error(
      `[AuthService] Error creating trainer profile:`,
      error.response?.data || error.message,
    );
  }
};

const checkIfEmailExistsInRecruiter = async (email) => {
  try {
    const response = await axios.get(
      `${RECRUITER_SERVICE_URL}/exists/${email}`,
    );
    return response.data.exists;
  } catch (error) {
    console.error("Error checking email in recruiter service:", error.message);
    return false;
  }
};

const checkIfEmailExistsInTrainer = async (email) => {
  try {
    const response = await axios.get(`${TRAINER_SERVICE_URL}/exists/${email}`);
    return response.data.exists;
  } catch (error) {
    console.error("Error checking email in trainer service:", error.message);
    return false;
  }
};

// ── JWT generation ────────────────────────────────────────────────────────────

const generateToken = (userId) => {
  const expiresIn =
    (process.env.JWT_EXPIRES_IN && process.env.JWT_EXPIRES_IN.trim()) || "24h";
  return jwt.sign({ id: userId, sub: userId }, process.env.JWT_SECRET, {
    expiresIn,
  });
};

// ── OTP generation ────────────────────────────────────────────────────────────

const generateOtp = () => Math.floor(1000 + Math.random() * 9000).toString();

// ── Standard user response shape ─────────────────────────────────────────────
// NOTE: token is NO LONGER included in the JSON body — it lives in the HttpOnly
// cookie set by setAuthCookie().  The client should read user data from this
// response body and store it in memory / CookieService (non-sensitive).

const userPayload = (user) => ({
  id: user._id,
  firstName: user.prenom,
  lastName: user.nom,
  email: user.email,
  role: user.role,
  sector: user.sector,
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/auth/exists/:email
// ─────────────────────────────────────────────────────────────────────────────
exports.checkEmailExists = async (req, res) => {
  try {
    const { email } = req.params;
    const user = await User.findOne({ email });
    if (user) return res.json({ exists: true });

    const existsInRecruiter = await checkIfEmailExistsInRecruiter(email);
    if (existsInRecruiter) return res.json({ exists: true });

    const existsInTrainer = await checkIfEmailExistsInTrainer(email);
    if (existsInTrainer) return res.json({ exists: true });

    res.json({ exists: false });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/register
// ─────────────────────────────────────────────────────────────────────────────
exports.register = async (req, res) => {
  try {
    const { firstName, lastName, email, password, role, entreprise, jobtitle } =
      req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({
          success: false,
          message: "Email et mot de passe sont requis.",
        });
    }

    if (role !== "recruteur" && (!firstName || !lastName)) {
      return res.status(400).json({
        success: false,
        message:
          "Le prénom et le nom sont requis pour les candidats/formateurs.",
      });
    }

    if (role === "recruteur") {
      return res.status(400).json({
        success: false,
        message:
          "Les recruteurs doivent s'inscrire via l'espace entreprise dédié.",
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res
        .status(409)
        .json({ success: false, message: "Cet email est déjà utilisé." });
    }

    const existsAsRecruiter = await checkIfEmailExistsInRecruiter(email);
    if (existsAsRecruiter) {
      return res
        .status(409)
        .json({ success: false, message: "Cet email est déjà utilisé." });
    }

    const existsAsTrainer = await checkIfEmailExistsInTrainer(email);
    if (existsAsTrainer) {
      return res
        .status(409)
        .json({ success: false, message: "Cet email est déjà utilisé." });
    }

    let userData = {
      email,
      password,
      role: role || "candidat",
      jobtitle: jobtitle || "",
      isVerified: false,
    };
    if (firstName) userData.prenom = firstName;
    if (lastName) userData.nom = lastName;

    const otp = generateOtp();
    userData.resetOtp = otp;
    userData.resetOtpExpires = new Date(Date.now() + 10 * 60 * 1000);

    const user = await User.create(userData);

    if (role === "formateur") {
      return res.status(400).json({
        success: false,
        message:
          "Les formateurs doivent s'inscrire via l'espace dédié aux formateurs.",
      });
    }

    // Send verification email in the background so the HTTP response isn't blocked
    sendVerificationEmail(user.email, otp).catch((err) =>
      console.error("[Register] Background email send failed:", err.message || err)
    );

    // DEV FALLBACK: print OTP to console so the developer can verify even if email fails
    console.log(`\n========================================`);
    console.log(`[DEV OTP] Registration OTP for ${user.email}: ${otp}`);
    console.log(`========================================\n`);

    res.status(201).json({
      success: true,
      message:
        "Compte créé. Un code de vérification a été envoyé à votre email.",
      requiresVerification: true,
      email: user.email,
    });
  } catch (error) {
    console.error("Register error:", error);
    res
      .status(500)
      .json({
        success: false,
        message: "Erreur serveur.",
        error: error.message,
      });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/verify-signup
// ─────────────────────────────────────────────────────────────────────────────
exports.verifySignupOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res
        .status(400)
        .json({ success: false, message: "Email et OTP requis." });
    }

    const user = await User.findOne({ email });
    if (!user)
      return res
        .status(404)
        .json({ success: false, message: "Utilisateur non trouvé." });

    if (user.resetOtp !== otp || user.resetOtpExpires < new Date()) {
      return res
        .status(400)
        .json({ success: false, message: "Code incorrect ou expiré." });
    }

    user.isVerified = true;
    user.resetOtp = null;
    user.resetOtpExpires = null;
    await user.save();

    const token = generateToken(user._id);

    // ← Set HttpOnly cookie
    setAuthCookie(res, token);

    res.status(200).json({
      success: true,
      message: "Email vérifié avec succès.",
      // token intentionally omitted from body — it's in the HttpOnly cookie
      user: userPayload(user),
    });
  } catch (error) {
    console.error("VerifySignupOtp error:", error);
    res
      .status(500)
      .json({
        success: false,
        message: "Erreur serveur.",
        error: error.message,
      });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/login
// ─────────────────────────────────────────────────────────────────────────────
exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ success: false, message: "Email et mot de passe requis." });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res
        .status(401)
        .json({ success: false, message: "Email ou mot de passe incorrect." });
    }

    if (!user.isVerified) {
      const otp = generateOtp();
      user.resetOtp = otp;
      user.resetOtpExpires = new Date(Date.now() + 10 * 60 * 1000);
      await user.save({ validateBeforeSave: false });
      // Resend verification email in the background so the HTTP response isn't blocked
      sendVerificationEmail(user.email, otp).catch((err) =>
        console.error("[Login] Background email resend failed:", err.message || err)
      );

      return res.status(403).json({
        success: false,
        message:
          "Votre compte n'est pas encore vérifié. Un nouveau code a été envoyé.",
        requiresVerification: true,
        email: user.email,
      });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res
        .status(401)
        .json({ success: false, message: "Email ou mot de passe incorrect." });
    }

    if (role === "formateur") {
      return res.status(403).json({
        success: false,
        message: "Les formateurs doivent se connecter via l'espace dédié.",
      });
    }

    if (role && user.role !== role) {
      return res
        .status(403)
        .json({ success: false, message: "Email ou mot de passe incorrect." });
    }

    const token = generateToken(user._id);

    // ← Set HttpOnly cookie
    setAuthCookie(res, token);

    // Fire-and-forget login notification
    sendLoginSuccessEmail(user.email, user.prenom).catch(() => { });

    res.status(200).json({
      success: true,
      message: "Connexion réussie.",
      // token intentionally omitted — it's in the HttpOnly cookie
      user: userPayload(user),
    });
  } catch (error) {
    console.error("Login error:", error);
    res
      .status(500)
      .json({
        success: false,
        message: "Erreur serveur.",
        error: error.message,
      });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/logout
// ─────────────────────────────────────────────────────────────────────────────
exports.logout = (req, res) => {
  // Clear the HttpOnly cookie — the browser will discard it
  clearAuthCookie(res);
  res.status(200).json({ success: true, message: "Déconnexion réussie." });
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/auth/me   (protected)
// ─────────────────────────────────────────────────────────────────────────────
// Used by Flutter on app startup to restore the session automatically.
// If the HttpOnly cookie is still valid, this returns the user profile.
exports.getMe = async (req, res) => {
  try {
    // req.user is populated by the protect middleware
    res.status(200).json({
      success: true,
      user: userPayload(req.user),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "Erreur serveur." });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/google
// ─────────────────────────────────────────────────────────────────────────────
exports.googleSignIn = async (req, res) => {
  try {
    const { idToken, accessToken, role } = req.body;

    if (!idToken && !accessToken) {
      return res
        .status(400)
        .json({
          success: false,
          message: "idToken ou accessToken est requis.",
        });
    }

    // Forward recruiter logins to the recruiter service
    if (role === "recruteur") {
      try {
        const recruiterResponse = await axios.post(
          "http://localhost:5002/api/recruiter/google",
          { idToken, accessToken },
        );
        // Recruiter service still returns a token in the body — set cookie here
        if (recruiterResponse.data?.token) {
          setAuthCookie(res, recruiterResponse.data.token);
        }
        return res.status(recruiterResponse.status).json({
          ...recruiterResponse.data,
          token: undefined, // strip token from body
        });
      } catch (recruiterError) {
        return res
          .status(recruiterError.response?.status || 500)
          .json(
            recruiterError.response?.data || {
              success: false,
              message: "Erreur authentification recruteur.",
            },
          );
      }
    }

    let email, given_name, family_name;

    if (idToken) {
      const ticket = await client.verifyIdToken({
        idToken,
        audience:
          "1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com",
      });
      const payload = ticket.getPayload();
      email = payload.email;
      given_name = payload.given_name;
      family_name = payload.family_name;
    } else {
      const response = await axios.get(
        "https://www.googleapis.com/oauth2/v3/userinfo",
        {
          headers: { Authorization: `Bearer ${accessToken}` },
        },
      );
      email = response.data.email;
      given_name = response.data.given_name;
      family_name = response.data.family_name;
    }

    if (!email)
      throw new Error(
        "Impossible de récupérer l'email de l'utilisateur Google.",
      );

    let user = await User.findOne({ email });

    if (!user) {
      const existsAsRecruiter = await checkIfEmailExistsInRecruiter(email);
      if (existsAsRecruiter && role !== "recruteur") {
        return res
          .status(403)
          .json({
            success: false,
            message: "Cet email est déjà utilisé par un recruteur.",
          });
      }

      const existsAsTrainer = await checkIfEmailExistsInTrainer(email);
      const randomPassword =
        Math.random().toString(36).slice(-8) +
        Math.random().toString(36).slice(-8);

      user = await User.create({
        prenom: given_name || "Utilisateur",
        nom: family_name || "Google",
        email,
        password: randomPassword,
        role: existsAsTrainer ? "formateur" : role || "candidat",
        isVerified: true,
      });
    }

    if (user.role === "formateur") {
      await createTrainerProfile(user._id, {
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
        isVerified: true,
      });
    }

    const token = generateToken(user._id);

    // ← Set HttpOnly cookie
    setAuthCookie(res, token);

    sendLoginSuccessEmail(user.email, user.prenom).catch(() => { });

    res.status(200).json({
      success: true,
      message: "Connexion Google réussie.",
      user: userPayload(user),
    });
  } catch (error) {
    console.error("Google Sign In error:", error);
    res
      .status(401)
      .json({
        success: false,
        message: "Authentification Google échouée.",
        error: error.message,
      });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/forgot-password
// ─────────────────────────────────────────────────────────────────────────────
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res
        .status(400)
        .json({ success: false, message: "L'email est requis." });
    }

    const otp = generateOtp();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000);

    const user = await User.findOne({ email });

    if (user) {
      user.resetOtp = otp;
      user.resetOtpExpires = otpExpires;
      await user.save({ validateBeforeSave: false });
    } else {
      let foundInRecruiter = false;
      try {
        const recruiterExist = await axios.get(
          `${RECRUITER_SERVICE_URL}/exists/${email}`,
        );
        if (recruiterExist.data.exists) {
          foundInRecruiter = true;
          try {
            await axios.post(`${RECRUITER_SERVICE_URL}/internal/set-otp`, {
              email,
              otp,
              otpExpires,
            });
          } catch (e) {
            console.error("Recruiter API set-otp error:", e.message);
          }
        }
      } catch (e) { }

      if (!foundInRecruiter) {
        try {
          const trainerExist = await axios.get(
            `${TRAINER_SERVICE_URL}/exists/${email}`,
          );
          if (trainerExist.data.exists) {
            await axios.post(`${TRAINER_SERVICE_URL}/internal/set-otp`, {
              email,
              otp,
              otpExpires,
            });
          } else {
            return res
              .status(200)
              .json({
                success: true,
                message: "Si cet email existe, un code a été envoyé.",
              });
          }
        } catch (e) {
          console.error("Trainer API set-otp error:", e.message);
          return res
            .status(200)
            .json({
              success: true,
              message: "Si cet email existe, un code a été envoyé.",
            });
        }
      }
    }

    // Send OTP email in the background so the HTTP response isn't blocked
    sendOtpEmail(email, otp).catch((err) =>
      console.error("[ForgotPassword] Background email send failed:", err.message || err)
    );

    // DEV FALLBACK: print OTP to console so the developer can verify even if email fails
    console.log(`\n========================================`);
    console.log(`[DEV OTP] Password-reset OTP for ${email}: ${otp}`);
    console.log(`========================================\n`);

    res
      .status(200)
      .json({ success: true, message: "Code OTP envoyé par email." });
  } catch (error) {
    console.error("ForgotPassword error:", error);
    res
      .status(500)
      .json({
        success: false,
        message: "Erreur lors de l'envoi de l'email.",
        error: error.message,
      });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/verify-otp
// ─────────────────────────────────────────────────────────────────────────────
exports.verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp)
      return res
        .status(400)
        .json({ success: false, message: "Email et OTP requis." });

    const user = await User.findOne({ email });

    if (user) {
      if (!user.resetOtp)
        return res
          .status(400)
          .json({ success: false, message: "OTP invalide ou expiré." });
      if (user.resetOtpExpires < new Date()) {
        user.resetOtp = null;
        user.resetOtpExpires = null;
        await user.save({ validateBeforeSave: false });
        return res
          .status(400)
          .json({
            success: false,
            message: "Le code OTP a expiré. Demandez un nouveau code.",
          });
      }
      if (user.resetOtp !== otp)
        return res
          .status(400)
          .json({ success: false, message: "Code incorrect. Réessayez." });
      return res
        .status(200)
        .json({ success: true, message: "Code vérifié avec succès." });
    }

    try {
      const trainerExists = await axios.get(
        `${TRAINER_SERVICE_URL}/exists/${email}`,
      );
      if (trainerExists.data.exists) {
        const verifyRes = await axios.post(
          `${TRAINER_SERVICE_URL}/internal/verify-otp`,
          { email, otp },
        );
        return res.status(verifyRes.status).json(verifyRes.data);
      }
    } catch (e) {
      if (e.response)
        return res.status(e.response.status).json(e.response.data);
    }

    try {
      const recruiterExists = await axios.get(
        `${RECRUITER_SERVICE_URL}/exists/${email}`,
      );
      if (recruiterExists.data.exists) {
        const verifyRes = await axios.post(
          `${RECRUITER_SERVICE_URL}/internal/verify-otp`,
          { email, otp },
        );
        return res.status(verifyRes.status).json(verifyRes.data);
      }
    } catch (e) {
      if (e.response)
        return res.status(e.response.status).json(e.response.data);
    }

    return res
      .status(400)
      .json({ success: false, message: "OTP invalide ou expiré." });
  } catch (error) {
    console.error("VerifyOtp error:", error);
    res
      .status(500)
      .json({
        success: false,
        message: "Erreur serveur.",
        error: error.message,
      });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/reset-password
// ─────────────────────────────────────────────────────────────────────────────
exports.resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) {
      return res
        .status(400)
        .json({
          success: false,
          message: "Email, OTP et nouveau mot de passe requis.",
        });
    }
    if (newPassword.length < 6) {
      return res
        .status(400)
        .json({
          success: false,
          message: "Le mot de passe doit contenir au moins 6 caractères.",
        });
    }

    const user = await User.findOne({ email });

    if (user) {
      if (!user.resetOtp)
        return res
          .status(400)
          .json({ success: false, message: "OTP invalide ou expiré." });
      if (user.resetOtpExpires < new Date()) {
        user.resetOtp = null;
        user.resetOtpExpires = null;
        await user.save({ validateBeforeSave: false });
        return res
          .status(400)
          .json({ success: false, message: "Le code OTP a expiré." });
      }
      if (user.resetOtp !== otp)
        return res
          .status(400)
          .json({ success: false, message: "Code incorrect." });

      user.password = newPassword;
      user.resetOtp = null;
      user.resetOtpExpires = null;
      await user.save();
      return res
        .status(200)
        .json({
          success: true,
          message: "Mot de passe réinitialisé avec succès.",
        });
    }

    try {
      const trainerExists = await axios.get(
        `${TRAINER_SERVICE_URL}/exists/${email}`,
      );
      if (trainerExists.data.exists) {
        const resetRes = await axios.post(
          `${TRAINER_SERVICE_URL}/internal/reset-password`,
          { email, otp, newPassword },
        );
        return res.status(resetRes.status).json(resetRes.data);
      }
    } catch (e) {
      if (e.response)
        return res.status(e.response.status).json(e.response.data);
    }

    try {
      const recruiterExists = await axios.get(
        `${RECRUITER_SERVICE_URL}/exists/${email}`,
      );
      if (recruiterExists.data.exists) {
        const resetRes = await axios.post(
          `${RECRUITER_SERVICE_URL}/internal/reset-password`,
          { email, otp, newPassword },
        );
        return res.status(resetRes.status).json(resetRes.data);
      }
    } catch (e) {
      if (e.response)
        return res.status(e.response.status).json(e.response.data);
    }

    return res
      .status(400)
      .json({ success: false, message: "OTP invalide ou expiré." });
  } catch (error) {
    console.error("ResetPassword error:", error);
    res
      .status(500)
      .json({
        success: false,
        message: "Erreur serveur.",
        error: error.message,
      });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/github
// ─────────────────────────────────────────────────────────────────────────────
exports.githubSignIn = async (req, res) => {
  try {
    const { code, role } = req.body;

    if (!code) {
      return res
        .status(400)
        .json({ success: false, message: "Le code GitHub est requis." });
    }

    if (role === "recruteur") {
      try {
        const recruiterResponse = await axios.post(
          "http://localhost:5002/api/recruiter/github",
          { code },
        );
        if (recruiterResponse.data?.token) {
          setAuthCookie(res, recruiterResponse.data.token);
        }
        return res.status(recruiterResponse.status).json({
          ...recruiterResponse.data,
          token: undefined,
        });
      } catch (recruiterError) {
        return res
          .status(recruiterError.response?.status || 500)
          .json(
            recruiterError.response?.data || {
              success: false,
              message: "Erreur authentification recruteur.",
            },
          );
      }
    }

    // Exchange code for access token
    const tokenResponse = await axios.post(
      "https://github.com/login/oauth/access_token",
      {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
      },
      { headers: { Accept: "application/json" } },
    );

    const accessToken = tokenResponse.data.access_token;
    if (!accessToken) {
      return res
        .status(400)
        .json({
          success: false,
          message: "Code GitHub invalide ou expiré.",
          details: tokenResponse.data,
        });
    }

    const userResponse = await axios.get("https://api.github.com/user", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    const githubUser = userResponse.data;

    let email = githubUser.email;
    if (!email) {
      const emailResponse = await axios.get(
        "https://api.github.com/user/emails",
        {
          headers: { Authorization: `Bearer ${accessToken}` },
        },
      );
      const primaryEmail = emailResponse.data.find(
        (e) => e.primary && e.verified,
      );
      email = primaryEmail ? primaryEmail.email : emailResponse.data[0].email;
    }

    if (!email) {
      return res
        .status(400)
        .json({
          success: false,
          message:
            "Impossible de récupérer une adresse email valide depuis GitHub.",
        });
    }

    let user = await User.findOne({ email });

    if (!user) {
      const existsAsRecruiter = await checkIfEmailExistsInRecruiter(email);
      if (existsAsRecruiter && role !== "recruteur") {
        return res
          .status(403)
          .json({
            success: false,
            message: "Cet email est déjà utilisé par un recruteur.",
          });
      }

      const existsAsTrainer = await checkIfEmailExistsInTrainer(email);
      const randomPassword =
        Math.random().toString(36).slice(-8) +
        Math.random().toString(36).slice(-8);
      const nameParts = (githubUser.name || githubUser.login).split(" ");

      user = await User.create({
        prenom: nameParts[0] || "Utilisateur",
        nom: nameParts.slice(1).join(" ") || "GitHub",
        email,
        password: randomPassword,
        role: existsAsTrainer ? "formateur" : role || "candidat",
        isVerified: true,
      });
    }

    if (user.role === "formateur") {
      await createTrainerProfile(user._id, {
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
        isVerified: true,
      });
    }

    const token = generateToken(user._id);

    // ← Set HttpOnly cookie
    setAuthCookie(res, token);

    sendLoginSuccessEmail(user.email, user.prenom).catch(() => { });

    res.status(200).json({
      success: true,
      message: "Connexion GitHub réussie.",
      user: userPayload(user),
    });
  } catch (error) {
    console.error("GitHub Sign In error:", error.response?.data || error);
    res
      .status(500)
      .json({
        success: false,
        message: "Authentification GitHub échouée.",
        error: error.message,
      });
  }
};

const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendOtpEmail, sendLoginSuccessEmail } = require('../services/emailService');
const { OAuth2Client } = require('google-auth-library');
const axios = require('axios');

const client = new OAuth2Client('1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com');

const RECRUITER_SERVICE_URL = 'http://127.0.0.1:5002/recruiter';
const TRAINER_SERVICE_URL = 'http://127.0.0.1:5004/api/formateur';

const createTrainerProfile = async (userId, data) => {
  try {
    await axios.put(`${TRAINER_SERVICE_URL}/profile/${userId}`, data);
  } catch (error) {
    console.error('Error creating trainer profile:', error.message);
  }
};

const checkIfEmailExistsInRecruiter = async (email) => {
  try {
    const url = `${RECRUITER_SERVICE_URL}/exists/${email}`;
    const response = await axios.get(url);
    return response.data.exists;
  } catch (error) {
    console.error('Error checking email in recruiter service:', error.message);
    return false;
  }
};

/**
 * @desc    Check if an email exists in candidat database
 * @route   GET /api/auth/exists/:email
 * @access  Public
 */
exports.checkEmailExists = async (req, res) => {
  try {
    const user = await User.findOne({ email: req.params.email });
    res.json({ exists: !!user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ── Générer un JWT
const generateToken = (userId) => {
  const expiresIn = (process.env.JWT_EXPIRES_IN && process.env.JWT_EXPIRES_IN.trim()) || '7d';
  console.log('Token generation details:', {
    userId,
    secretExists: !!process.env.JWT_SECRET,
    expiresIn: `"${expiresIn}"`
  });

  return jwt.sign({ id: userId, sub: userId }, process.env.JWT_SECRET, {
    expiresIn: expiresIn,
  });
};

// ── Générer un OTP 4 chiffres 
const generateOtp = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { firstName, lastName, email, password, role, entreprise, jobtitle } = req.body;

    // Validation basique
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email et mot de passe sont requis.',
      });
    }

    if (role !== 'recruteur' && (!firstName || !lastName)) {
      return res.status(400).json({
        success: false,
        message: 'Le prénom et le nom sont requis pour les candidats/formateurs.',
      });
    }

    if (role === 'recruteur') {
      return res.status(400).json({
        success: false,
        message: 'Les recruteurs doivent s\'inscrire via l\'espace entreprise dédié.',
      });
    }

    // Vérifier si l'email existe déjà localement
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Cet email est déjà utilisé.',
      });
    }

    // Vérifier dans le service recruteur
    const existsAsRecruiter = await checkIfEmailExistsInRecruiter(email);
    if (existsAsRecruiter) {
      return res.status(409).json({
        success: false,
        message: 'Cet email est déjà utilisé .',
      });
    }

    // Créer l'utilisateur
    let userData = {
      email,
      password,
      role: role || 'candidat',
      jobtitle: jobtitle || '',
    };
    if (firstName) userData.prenom = firstName;
    if (lastName) userData.nom = lastName;

    let user = await User.create(userData);

    // Initialiser le profil dans le trainer-service si c'est un formateur
    if (user.role === 'formateur') {
      await createTrainerProfile(user._id, {
        firstName: firstName,
        lastName: lastName,
        email: email,
      });
    }

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Compte créé avec succès.',
      token,
      user: {
        id: user._id,
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
        role: user.role,
        sector: user.sector,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur.',
      error: error.message,
    });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email et mot de passe requis.',
      });
    }

    // Trouver l'utilisateur
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Email ou mot de passe incorrect.',
      });
    }

    // Vérifier le mot de passe
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Email ou mot de passe incorrect.',
      });
    }

    // Vérifier le rôle si fourni
    if (role && user.role !== role) {
      return res.status(403).json({
        success: false,
        message: `Ce compte n'est pas un compte ${role}.`,
      });
    }

    const token = generateToken(user._id);

    // Envoyer email de notification de connexion
    sendLoginSuccessEmail(user.email, user.prenom);

    res.status(200).json({
      success: true,
      message: 'Connexion réussie.',
      token,
      user: {
        id: user._id,
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur.',
      error: error.message,
    });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/auth/google
// ─────────────────────────────────────────────────────────────────────────────
exports.googleSignIn = async (req, res) => {
  try {
    const { idToken, accessToken, role } = req.body;

    if (!idToken && !accessToken) {
      return res.status(400).json({
        success: false,
        message: 'idToken ou accessToken est requis.',
      });
    }

    // Forward to recruiter service if needed
    if (role === 'recruteur') {
      try {
        const recruiterResponse = await axios.post('http://localhost:5002/api/recruiter/google', { idToken, accessToken });
        return res.status(recruiterResponse.status).json(recruiterResponse.data);
      } catch (recruiterError) {
        console.error('Error forwarding google auth to recruiter service:', recruiterError.response?.data || recruiterError.message);
        return res.status(recruiterError.response?.status || 500).json(recruiterError.response?.data || {
          success: false,
          message: 'Erreur lors de l\'authentification recruteur.',
          error: recruiterError.message
        });
      }
    }

    let email, given_name, family_name;

    if (idToken) {
      // Verify idToken using google-auth-library
      const ticket = await client.verifyIdToken({
        idToken,
        audience: '1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com',
      });
      const payload = ticket.getPayload();
      email = payload.email;
      given_name = payload.given_name;
      family_name = payload.family_name;
    } else {
      // Verify accessToken using Google UserInfo API
      const response = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` }
      });
      email = response.data.email;
      given_name = response.data.given_name;
      family_name = response.data.family_name;
    }

    if (!email) {
      throw new Error('Impossible de récupérer l\'email de l\'utilisateur Google.');
    }

    // Vérifier si l'utilisateur existe déjà
    let user = await User.findOne({ email });

    if (!user) {
      // Vérifier si l'email existe en tant que recruteur avant de créer un candidat
      const existsAsRecruiter = await checkIfEmailExistsInRecruiter(email);
      if (existsAsRecruiter) {
        return res.status(403).json({
          success: false,
          message: 'Cet email est déjà utilisé .',
        });
      }

      // Créer un utilisateur s'il n'existe pas
      // Générer un mdp aléatoire très fort vu qu'il se connectera via Google
      const randomPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8);
      user = await User.create({
        prenom: given_name || 'Utilisateur',
        nom: family_name || 'Google',
        email: email,
        password: randomPassword,
        role: role || 'candidat',
      });
    }

    // Initialiser le profil dans le trainer-service si c'est un formateur
    if (user.role === 'formateur') {
      await createTrainerProfile(user._id, {
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
      });
    }

    const token = generateToken(user._id);

    // Envoyer email de notification de connexion
    sendLoginSuccessEmail(user.email, user.prenom);

    res.status(200).json({
      success: true,
      message: 'Connexion Google réussie.',
      token,
      user: {
        id: user._id,
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('Google Sign In error:', error);
    res.status(401).json({
      success: false,
      message: 'Authentification Google échouée.',
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
      return res.status(400).json({
        success: false,
        message: "L'email est requis.",
      });
    }

    const user = await User.findOne({ email });
    if (!user) {
      // Sécurité : ne pas révéler si l'email existe
      return res.status(200).json({
        success: true,
        message: 'Si cet email existe, un code a été envoyé.',
      });
    }

    // Générer OTP
    const otp = generateOtp();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Sauvegarder OTP hashé
    user.resetOtp = otp;
    user.resetOtpExpires = otpExpires;
    await user.save({ validateBeforeSave: false });

    // Envoyer email
    await sendOtpEmail(email, otp);

    res.status(200).json({
      success: true,
      message: 'Code OTP envoyé par email.',
    });
  } catch (error) {
    console.error('ForgotPassword error:', error);
    res.status(500).json({
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

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Email et OTP requis.',
      });
    }

    const user = await User.findOne({ email });

    if (!user || !user.resetOtp) {
      return res.status(400).json({
        success: false,
        message: 'OTP invalide ou expiré.',
      });
    }

    // Vérifier expiration
    if (user.resetOtpExpires < new Date()) {
      user.resetOtp = null;
      user.resetOtpExpires = null;
      await user.save({ validateBeforeSave: false });
      return res.status(400).json({
        success: false,
        message: 'Le code OTP a expiré. Demandez un nouveau code.',
      });
    }

    // Vérifier OTP
    if (user.resetOtp !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Code incorrect. Réessayez.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Code vérifié avec succès.',
    });
  } catch (error) {
    console.error('VerifyOtp error:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur.',
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
      return res.status(400).json({
        success: false,
        message: 'Email, OTP et nouveau mot de passe requis.',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Le mot de passe doit contenir au moins 6 caractères.',
      });
    }

    const user = await User.findOne({ email });

    if (!user || !user.resetOtp) {
      return res.status(400).json({
        success: false,
        message: 'OTP invalide ou expiré.',
      });
    }

    if (user.resetOtpExpires < new Date()) {
      user.resetOtp = null;
      user.resetOtpExpires = null;
      await user.save({ validateBeforeSave: false });
      return res.status(400).json({
        success: false,
        message: 'Le code OTP a expiré.',
      });
    }

    if (user.resetOtp !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Code incorrect.',
      });
    }

    // Mettre à jour le mot de passe
    user.password = newPassword;
    user.resetOtp = null;
    user.resetOtpExpires = null;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Mot de passe réinitialisé avec succès.',
    });
  } catch (error) {
    console.error('ResetPassword error:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur.',
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
      return res.status(400).json({
        success: false,
        message: 'Le code GitHub est requis.',
      });
    }

    // Verify if it's a recruiter and forward if needed
    if (role === 'recruteur') {
      try {
        const recruiterResponse = await axios.post('http://localhost:5002/api/recruiter/github', { code });
        return res.status(recruiterResponse.status).json(recruiterResponse.data);
      } catch (recruiterError) {
        console.error('Error forwarding github auth to recruiter service:', recruiterError.response?.data || recruiterError.message);
        return res.status(recruiterError.response?.status || 500).json(recruiterError.response?.data || {
          success: false,
          message: 'Erreur lors de l\'authentification recruteur.',
          error: recruiterError.message
        });
      }
    }

    // 1. Échanger le code contre un access token
    const tokenResponse = await axios.post(
      'https://github.com/login/oauth/access_token',
      {
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
      },
      {
        headers: {
          Accept: 'application/json',
        },
      }
    );

    const accessToken = tokenResponse.data.access_token;

    if (!accessToken) {
      return res.status(400).json({
        success: false,
        message: 'Code GitHub invalide ou expiré.',
        details: tokenResponse.data
      });
    }

    // 2. Récupérer les infos de l'utilisateur depuis l'API GitHub
    const userResponse = await axios.get('https://api.github.com/user', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    const githubUser = userResponse.data;

    // 3. Récupérer l'email (il peut être privé sur GitHub)
    let email = githubUser.email;
    if (!email) {
      const emailResponse = await axios.get('https://api.github.com/user/emails', {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });
      // Try to find the primary verified email, otherwise fallback to the first one
      const primaryEmail = emailResponse.data.find(e => e.primary && e.verified);
      email = primaryEmail ? primaryEmail.email : emailResponse.data[0].email;
    }

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Impossible de récupérer une adresse email valide depuis GitHub.',
      });
    }

    // Vérifier si l'utilisateur existe déjà
    let user = await User.findOne({ email });

    if (!user) {
      // Vérifier si l'email existe en tant que recruteur avant de créer un candidat
      const existsAsRecruiter = await checkIfEmailExistsInRecruiter(email);
      if (existsAsRecruiter) {
        return res.status(403).json({
          success: false,
          message: 'Cet email est déjà utilisé par un recruteur.',
        });
      }

      // Créer un utilisateur s'il n'existe pas
      // Générer un mdp aléatoire très fort pour qu'il puisse se connecter nativement plus tard si besoin
      const randomPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8);
      const nameParts = (githubUser.name || githubUser.login).split(' ');

      user = await User.create({
        prenom: nameParts[0] || 'Utilisateur',
        nom: nameParts.slice(1).join(' ') || 'GitHub',
        email: email,
        password: randomPassword,
        role: role || 'candidat',
      });
    }

    // Initialiser le profil dans le trainer-service si c'est un formateur
    if (user.role === 'formateur') {
      await createTrainerProfile(user._id, {
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
      });
    }

    const token = generateToken(user._id);

    // Envoyer email de notification de connexion
    sendLoginSuccessEmail(user.email, user.prenom);

    res.status(200).json({
      success: true,
      message: 'Connexion GitHub réussie.',
      token,
      user: {
        id: user._id,
        firstName: user.prenom,
        lastName: user.nom,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('GitHub Sign In error:', error.response?.data || error);
    res.status(500).json({
      success: false,
      message: 'Authentification GitHub échouée.',
      error: error.message,
    });
  }
};
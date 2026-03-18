const express = require('express');
const router = express.Router();
const {
  register,
  login,
  forgotPassword,
  verifyOtp,
  resetPassword,
  googleSignIn,
  githubSignIn,
} = require('../controllers/authController');

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);

// Google Sign In
router.post('/google', googleSignIn);

// GitHub Sign In
router.post('/github', githubSignIn);

// GitHub OAuth Callback (browser redirect)
router.get('/github/callback', async (req, res) => {
  const { code } = req.query;
  if (!code) {
    return res.status(400).send('<h2>❌ Erreur: code manquant</h2>');
  }
  // Show a page that tells the user to go back to the app and paste the code
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>SkillSpace - GitHub Connexion</title>
      <style>
        body { font-family: -apple-system, sans-serif; display:flex; justify-content:center; align-items:center; min-height:100vh; margin:0; background:#f0f2f5; }
        .card { background:white; padding:40px; border-radius:20px; text-align:center; box-shadow:0 4px 20px rgba(0,0,0,0.1); max-width:400px; }
        h2 { color:#1a2666; margin-bottom:8px; }
        p { color:#555; margin-bottom:20px; }
        code { background:#f0f0f0; padding:12px 20px; border-radius:10px; font-size:18px; font-weight:bold; display:block; letter-spacing:2px; color:#333; }
        .hint { color:#888; font-size:12px; margin-top:12px; }
      </style>
    </head>
    <body>
      <div class="card">
        <h2>✅ GitHub Connecté !</h2>
        <p>Copiez ce code et collez-le dans l'application SkillSpace :</p>
        <code>${code}</code>
        <p class="hint">Ce code est unique et expire rapidement.</p>
      </div>
    </body>
    </html>
  `);
});

module.exports = router;
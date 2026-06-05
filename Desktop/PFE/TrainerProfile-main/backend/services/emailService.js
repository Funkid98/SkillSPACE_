const nodemailer = require('nodemailer');

// Lazy transporter — only created when GMAIL_USER & GMAIL_PASS are set
let _transporter = null;
const getTransporter = () => {
  if (!process.env.GMAIL_USER || !process.env.GMAIL_PASS) return null;
  if (!_transporter) {
    _transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_PASS,
      },
      pool: false,
      connectionTimeout: 5000,
      greetingTimeout: 5000,
      socketTimeout: 5000,
    });
  }
  return _transporter;
};

const sendVerificationEmail = async (toEmail, otp) => {
  const mailOptions = {
    from: `"SkillSpace" <${process.env.GMAIL_FROM}>`,
    to: toEmail,
    subject: ' Vérifiez votre compte SkillSpace (Formateur)',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f5f3ee; border-radius: 16px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1E2B6B; font-size: 24px; margin: 0;">SkillSpace</h1>
        </div>
        <div style="background: white; border-radius: 12px; padding: 24px; text-align: center;">
          <h2 style="color: #1A1A2E; font-size: 20px;">Vérification de votre compte Formateur</h2>
          <p style="color: #8A8A9A; font-size: 14px;">Bienvenue sur SkillSpace ! Utilisez ce code pour vérifier votre adresse email et finaliser votre inscription en tant que formateur.</p>
          <div style="background: #F0F4FF; border: 2px solid #1E2B6B; border-radius: 12px; padding: 20px; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: 800; color: #1E2B6B; letter-spacing: 12px;">${otp}</span>
          </div>
          <p style="color: #8A8A9A; font-size: 12px;">Ce code expirera dans <strong>10 minutes</strong>.</p>
        </div>
      </div>
    `,
  };

  const transporter = getTransporter();
  if (!transporter) { console.warn('[Email] GMAIL_USER/GMAIL_PASS not set — skipping verification email.'); return; }
  try {
    await transporter.sendMail(mailOptions);
  } catch (err) {
    console.error(`[Email] Failed to send verification email to ${toEmail}:`, err.message || err);
  }
};

const sendLoginSuccessEmail = async (toEmail, firstName) => {
  const mailOptions = {
    from: `"SkillSpace Security" <${process.env.GMAIL_FROM}>`,
    to: toEmail,
    subject: 'Nouvelle connexion à votre compte SkillSpace',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f5f3ee; border-radius: 16px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1E2B6B; font-size: 24px; margin: 0;">SkillSpace</h1>
        </div>
        <div style="background: white; border-radius: 12px; padding: 24px;">
          <h2 style="color: #1A1A2E; font-size: 20px; text-align: center;">Bonjour ${firstName},</h2>
          <p style="color: #8A8A9A; font-size: 14px; line-height: 1.6;">Nous vous informons qu'une connexion vient d'être effectuée sur votre compte Formateur SkillSpace.</p>
          <p style="color: #8A8A9A; font-size: 14px; line-height: 1.6;">Si c'était vous, vous pouvez ignorer cet email.</p>
        </div>
      </div>
    `,
  };

  try {
    const transporter = getTransporter();
    if (!transporter) return;
    await transporter.sendMail(mailOptions);
  } catch (error) {
    console.error(`[Email] Failed to send login success email to ${toEmail}:`, error.message || error);
  }
};

const sendPasswordResetEmail = async (toEmail, otp) => {
  const mailOptions = {
    from: `"SkillSpace Security" <${process.env.GMAIL_FROM}>`,
    to: toEmail,
    subject: 'Réinitialisation de votre mot de passe SkillSpace',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f5f3ee; border-radius: 16px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1E2B6B; font-size: 24px; margin: 0;">SkillSpace</h1>
        </div>
        <div style="background: white; border-radius: 12px; padding: 24px; text-align: center;">
          <h2 style="color: #1A1A2E; font-size: 20px;">Réinitialisation de mot de passe</h2>
          <p style="color: #8A8A9A; font-size: 14px;">Vous avez demandé la réinitialisation de votre mot de passe. Utilisez le code ci-dessous pour continuer.</p>
          <div style="background: #FFF0F0; border: 2px solid #E63946; border-radius: 12px; padding: 20px; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: 800; color: #E63946; letter-spacing: 12px;">${otp}</span>
          </div>
          <p style="color: #8A8A9A; font-size: 12px;">Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
        </div>
      </div>
    `,
  };

  const transporter = getTransporter();
  if (!transporter) return;
  try {
    await transporter.sendMail(mailOptions);
  } catch (err) {
    console.error(`[Email] Failed to send password reset email to ${toEmail}:`, err.message || err);
  }
};

module.exports = { sendVerificationEmail, sendLoginSuccessEmail, sendPasswordResetEmail };

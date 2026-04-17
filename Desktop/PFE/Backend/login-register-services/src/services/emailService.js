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
    });
  }
  return _transporter;
};

const sendOtpEmail = async (toEmail, otp) => {
  const mailOptions = {
    from: `"SkillSpace" <${process.env.GMAIL_FROM}>`,
    to: toEmail,
    subject: '🔐 Code de réinitialisation SkillSpace',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f5f3ee; border-radius: 16px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1E2B6B; font-size: 24px; margin: 0;">⭐ SkillSpace</h1>
        </div>
        <div style="background: white; border-radius: 12px; padding: 24px; text-align: center;">
          <h2 style="color: #1A1A2E; font-size: 20px;">Réinitialisation du mot de passe</h2>
          <p style="color: #8A8A9A; font-size: 14px;">Utilisez ce code pour réinitialiser votre mot de passe. Il expire dans <strong>10 minutes</strong>.</p>
          <div style="background: #FDF0EA; border: 2px solid #E8622A; border-radius: 12px; padding: 20px; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: 800; color: #E8622A; letter-spacing: 12px;">${otp}</span>
          </div>
          <p style="color: #8A8A9A; font-size: 12px;">Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
        </div>
      </div>
    `,
  };

  const transporter = getTransporter();
  if (!transporter) { console.warn('[Email] GMAIL_USER/GMAIL_PASS not set — skipping OTP email.'); return; }
  await transporter.sendMail(mailOptions);
};

const sendLoginSuccessEmail = async (toEmail, firstName) => {
  const mailOptions = {
    from: `"SkillSpace Security" <${process.env.GMAIL_FROM}>`,
    to: toEmail,
    subject: '🔔 Nouvelle connexion à votre compte SkillSpace',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f5f3ee; border-radius: 16px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1E2B6B; font-size: 24px; margin: 0;">⭐ SkillSpace</h1>
        </div>
        <div style="background: white; border-radius: 12px; padding: 24px;">
          <h2 style="color: #1A1A2E; font-size: 20px; text-align: center;">Bonjour ${firstName},</h2>
          <p style="color: #8A8A9A; font-size: 14px; line-height: 1.6;">Nous vous informons qu'une connexion vient d'être effectuée sur votre compte SkillSpace.</p>
          <p style="color: #8A8A9A; font-size: 14px; line-height: 1.6;">Si c'était vous, vous pouvez ignorer cet email. Si vous ne reconnaissez pas cette activité, nous vous recommandons de réinitialiser votre mot de passe immédiatement.</p>
          <div style="text-align: center; margin-top: 24px;">
            <a href="#" style="background: #1E2B6B; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 14px;">Sécuriser mon compte</a>
          </div>
        </div>
        <div style="text-align: center; margin-top: 24px;">
          <p style="color: #8A8A9A; font-size: 11px;">&copy; 2025 SkillSpace Inc. Tous droits réservés.</p>
        </div>
      </div>
    `,
  };

  try {
    const transporter = getTransporter();
    if (!transporter) { console.warn('[Email] GMAIL_USER/GMAIL_PASS not set — skipping login notification.'); return; }
    await transporter.sendMail(mailOptions);
  } catch (error) {
    console.error('Error sending login notification email:', error);
  }
};

module.exports = { sendOtpEmail, sendLoginSuccessEmail };
const nodemailer = require("nodemailer");

let _transporter = null;
const getTransporter = () => {
  if (!process.env.GMAIL_USER || !process.env.GMAIL_PASS) return null;
  if (!_transporter) {
    _transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_PASS,
      },
    });
  }
  return _transporter;
};

const sendVerificationEmail = async (toEmail, otp) => {
  const mailOptions = {
    from: `"SkillSpace" <${process.env.GMAIL_FROM}>`,
    to: toEmail,
    subject: " Vérifiez votre compte SkillSpace",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f5f3ee; border-radius: 16px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #1E2B6B; font-size: 24px; margin: 0;">SkillSpace</h1>
        </div>
        <div style="background: white; border-radius: 12px; padding: 24px; text-align: center;">
          <h2 style="color: #1A1A2E; font-size: 20px;">Vérification de votre compte Recruteur</h2>
          <p style="color: #8A8A9A; font-size: 14px;">Utilisez ce code pour vérifier votre adresse email et finaliser votre inscription en tant que recruteur.</p>
          <div style="background: #FDF0EA; border: 2px solid #E8622A; border-radius: 12px; padding: 20px; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: 800; color: #E8622A; letter-spacing: 12px;">${otp}</span>
          </div>
          <p style="color: #8A8A9A; font-size: 12px;">Ce code expirera dans <strong>10 minutes</strong>.</p>
        </div>
      </div>
    `,
  };

  const transporter = getTransporter();
  if (!transporter) return;
  await transporter.sendMail(mailOptions);
};

module.exports = { sendVerificationEmail };

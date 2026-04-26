const Recruiter = require('../models/recruiter');
const axios = require('axios');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');

const client = new OAuth2Client('1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com');

const CANDIDAT_SERVICE_URL = 'http://localhost:5001/api/auth';

const generateToken = (id, entreprise) => {
    return jwt.sign({ id, entreprise }, process.env.JWT_SECRET, {
        expiresIn: '30d'
    });
};

const checkIfEmailExistsInCandidat = async (email) => {
    try {
        const response = await axios.get(`${CANDIDAT_SERVICE_URL}/exists/${email}`);
        return response.data.exists;
    } catch (error) {
        console.error('Error checking email in candidat service:', error.message);
        return false; // Fallback to false if service is down, or we could throw
    }
};

/**
 * @desc    Check if an email exists in recruiter database
 * @route   GET /api/recruiter/exists/:email
 * @access  Public
 */
const checkRecruiterEmailExists = async (req, res) => {
    try {
        const recruiter = await Recruiter.findOne({ email: req.params.email });
        res.json({ exists: !!recruiter });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Register a new recruiter
// @route   POST /api/recruiter/register
// @access  Public
const registerRecruiter = async (req, res) => {
    try {
        const { email, password, entreprise, poste } = req.body;

        const recruiterExists = await Recruiter.findOne({ email });

        if (recruiterExists) {
            return res.status(400).json({ message: 'Cet email est déjà utilisé par un recruteur.' });
        }

        // Check in candidat service
        const existsAsCandidat = await checkIfEmailExistsInCandidat(email);
        if (existsAsCandidat) {
            return res.status(400).json({ message: 'Cet email est déjà utilisé par un candidat.' });
        }

        const recruiter = await Recruiter.create({
            email,
            password,
            entreprise,
            poste
        });

        if (recruiter) {
            res.status(201).json({
                _id: recruiter._id,
                email: recruiter.email,
                entreprise: recruiter.entreprise,
                poste: recruiter.poste,
                role: recruiter.role,
                token: generateToken(recruiter._id, recruiter.entreprise),
                message: `Bienvenue "${recruiter.entreprise}"`
            });
        } else {
            res.status(400).json({ message: 'Invalid recruiter data' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Auth recruiter & get token
// @route   POST /api/recruiter/login
// @access  Public
const authRecruiter = async (req, res) => {
    try {
        const { email, password } = req.body;

        const recruiter = await Recruiter.findOne({ email });

        if (recruiter && (await recruiter.matchPassword(password))) {
            res.json({
                _id: recruiter._id,
                email: recruiter.email,
                entreprise: recruiter.entreprise,
                poste: recruiter.poste,
                role: recruiter.role,
                token: generateToken(recruiter._id, recruiter.entreprise),
                message: `Bienvenue "${recruiter.entreprise}"`
            });
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get recruiter profile
// @route   GET /api/recruiter/profile
// @access  Private
const getRecruiterProfile = async (req, res) => {
    try {
        const recruiter = await Recruiter.findById(req.user._id);

        if (recruiter) {
            res.json({
                _id: recruiter._id,
                email: recruiter.email,
                entreprise: recruiter.entreprise,
                poste: recruiter.poste,
                role: recruiter.role,
                taille: recruiter.taille,
                anneeCreation: recruiter.anneeCreation,
                siteWeb: recruiter.siteWeb,
                localisation: recruiter.localisation,
                logo: recruiter.logo,
                secteur: recruiter.secteur
            });
        } else {
            res.status(404).json({ message: 'Recruiter not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update recruiter profile
// @route   PUT /api/recruiter/profile
// @access  Private
const updateRecruiterProfile = async (req, res) => {
    try {
        const recruiter = await Recruiter.findById(req.user._id);

        if (recruiter) {
            recruiter.entreprise = req.body.entreprise || recruiter.entreprise;
            recruiter.poste = req.body.poste || recruiter.poste;
            recruiter.taille = req.body.taille || recruiter.taille;
            recruiter.anneeCreation = req.body.anneeCreation || recruiter.anneeCreation;
            recruiter.siteWeb = req.body.siteWeb || recruiter.siteWeb;
            recruiter.localisation = req.body.localisation || recruiter.localisation;
            recruiter.logo = req.body.logo || recruiter.logo;
            recruiter.secteur = req.body.secteur || recruiter.secteur;

            const updatedRecruiter = await recruiter.save();

            res.json({
                _id: updatedRecruiter._id,
                email: updatedRecruiter.email,
                entreprise: updatedRecruiter.entreprise,
                poste: updatedRecruiter.poste,
                role: updatedRecruiter.role,
                taille: updatedRecruiter.taille,
                anneeCreation: updatedRecruiter.anneeCreation,
                siteWeb: updatedRecruiter.siteWeb,
                localisation: updatedRecruiter.localisation,
                logo: updatedRecruiter.logo,
                secteur: updatedRecruiter.secteur
            });
        } else {
            res.status(404).json({ message: 'Recruiter not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Auth recruiter with Google
// @route   POST /api/recruiter/google
// @access  Public
const googleSignInForRecruiter = async (req, res) => {
    try {
        const { idToken, accessToken } = req.body;

        if (!idToken && !accessToken) {
            return res.status(400).json({ success: false, message: 'idToken or accessToken is required' });
        }

        let email;

        if (idToken) {
            const ticket = await client.verifyIdToken({
                idToken,
                audience: '1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com',
            });
            const payload = ticket.getPayload();
            email = payload.email;
        } else {
            // Verify access token using Google UserInfo API
            const response = await axios.get('https://www.googleapis.com/oauth2/v3/userinfo', {
                headers: { Authorization: `Bearer ${accessToken}` }
            });
            email = response.data.email;
        }

        if (!email) {
            throw new Error('Could not retrieve email from Google');
        }

        let recruiter = await Recruiter.findOne({ email });
        if (!recruiter) {
            // Check in candidat service before creating
            const existsAsCandidat = await checkIfEmailExistsInCandidat(email);
            if (existsAsCandidat) {
                return res.status(400).json({ success: false, message: 'Cet email est déjà utilisé par un candidat.' });
            }

            const randomPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8);
            recruiter = await Recruiter.create({
                email,
                password: randomPassword,
                entreprise: 'A définir',
                poste: 'Recruteur',
                role: 'recruteur'
            });
        }

        res.status(200).json({
            success: true,
            message: `Bienvenue "${recruiter.entreprise}"`,
            token: generateToken(recruiter._id, recruiter.entreprise),
            user: {
                id: recruiter._id,
                email: recruiter.email,
                entreprise: recruiter.entreprise,
                poste: recruiter.poste,
                role: recruiter.role,
                firstName: 'Recruteur',
                lastName: ''
            }
        });
    } catch (error) {
        console.error('Google Sign In error:', error);
        res.status(401).json({ success: false, message: 'Authentification Google échouée.', error: error.message });
    }
};

// @desc    Auth recruiter with GitHub
// @route   POST /api/recruiter/github
// @access  Public
const githubSignInForRecruiter = async (req, res) => {
    try {
        const { code } = req.body;

        if (!code) {
            return res.status(400).json({ success: false, message: 'Le code GitHub est requis.' });
        }

        // 1. Échanger le code contre un access token
        const tokenResponse = await axios.post(
            'https://github.com/login/oauth/access_token',
            {
                client_id: process.env.GITHUB_CLIENT_ID || 'Ov23li9VlgIH94DHCcgx',
                client_secret: process.env.GITHUB_CLIENT_SECRET,
                code,
            },
            {
                headers: { Accept: 'application/json' },
            }
        );

        const accessToken = tokenResponse.data.access_token;

        if (!accessToken) {
            return res.status(400).json({ success: false, message: 'Code GitHub invalide ou expiré.' });
        }

        // 2. Récupérer les infos de l'utilisateur
        const userResponse = await axios.get('https://api.github.com/user', {
            headers: { Authorization: `Bearer ${accessToken}` },
        });

        const githubUser = userResponse.data;

        // 3. Récupérer l'email
        let email = githubUser.email;
        if (!email) {
            const emailResponse = await axios.get('https://api.github.com/user/emails', {
                headers: { Authorization: `Bearer ${accessToken}` },
            });
            const primaryEmail = emailResponse.data.find(e => e.primary && e.verified);
            email = primaryEmail ? primaryEmail.email : emailResponse.data[0].email;
        }

        if (!email) {
            return res.status(400).json({ success: false, message: 'Impossible de récupérer une adresse email depuis GitHub.' });
        }

        let recruiter = await Recruiter.findOne({ email });
        if (!recruiter) {
            // Check in candidat service before creating
            const existsAsCandidat = await checkIfEmailExistsInCandidat(email);
            if (existsAsCandidat) {
                return res.status(400).json({ success: false, message: 'Cet email est déjà utilisé par un candidat.' });
            }

            const randomPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8);
            recruiter = await Recruiter.create({
                email,
                password: randomPassword,
                entreprise: 'A définir',
                poste: 'Recruteur',
                role: 'recruteur'
            });
        }

        res.status(200).json({
            success: true,
            message: `Bienvenue "${recruiter.entreprise}"`,
            token: generateToken(recruiter._id, recruiter.entreprise),
            user: {
                id: recruiter._id,
                email: recruiter.email,
                entreprise: recruiter.entreprise,
                role: recruiter.role,
                firstName: githubUser.name || githubUser.login || 'Recruteur',
                lastName: ''
            }
        });
    } catch (error) {
        console.error('GitHub Sign In error:', error);
        res.status(500).json({ success: false, message: 'Authentification GitHub échouée.', error: error.message });
    }
};

// ============== NOTIFICATIONS AND CONTACT =====================

const Notification = require('../models/notification');

// Contact a candidate
const contactCandidate = async (req, res) => {
    try {
        const { candidateId, candidateName } = req.body;
        const recruiterId = req.user._id;

        if (!candidateId) return res.status(400).json({ error: 'Missing candidateId' });

        const recruiter = await Recruiter.findById(recruiterId).lean();

        // Notify Candidat Service
        try {
            await axios.post('http://127.0.0.1:5000/candidat/internal/notify', {
                candidateId: candidateId,
                senderId: recruiterId,
                senderName: recruiter.entreprise || 'Un recruteur',
                senderEmail: recruiter.email,
                message: `L'entreprise ${recruiter.entreprise} souhaite vous contacter.`,
                type: 'CONTACT'
            });
        } catch (e) {
            console.error('Failed to notify candidate:', e.message);
        }

        res.json({ message: 'Demande de contact envoyée avec succès' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Internal endpoint to receive notification
const receiveNotification = async (req, res) => {
    try {
        const { recruiterId, senderId, senderName, senderEmail, message, type, offerId, offerTitle } = req.body;
        const notif = new Notification({
            userId: recruiterId,
            senderId,
            senderName,
            senderEmail,
            message,
            type,
            offerId,
            offerTitle
        });
        await notif.save();
        res.json({ message: 'Notification received' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

const handleApplicationDecision = async (req, res) => {
    try {
        const { notificationId, decision, interviewDate, interviewTime, meetingLink, rejectionReason } = req.body;
        const recruiterId = req.user._id;

        const notification = await Notification.findById(notificationId);
        if (!notification) return res.status(404).json({ error: 'Notification not found' });
        if (notification.decisionMade) return res.status(400).json({ error: 'Decision already made for this application' });

        const recruiter = await Recruiter.findById(recruiterId);

        // Call Candidat Service to update application status
        try {
            await axios.post('http://127.0.0.1:5000/candidat/internal/application/update', {
                candidateId: notification.senderId,
                offerId: notification.offerId,
                offerTitle: notification.offerTitle,
                status: decision === 'ACCEPT' ? 'ACCEPTED' : 'REJECTED',
                interviewDate,
                interviewTime,
                meetingLink,
                rejectionReason,
                recruiterName: recruiter.entreprise,
                recruiterEmail: recruiter.email
            });
        } catch (e) {
            console.error('Failed to update candidate application:', e.message);
            return res.status(500).json({ error: 'Failed to sync decision with candidate service' });
        }

        // Mark decision as made
        notification.decisionMade = true;
        notification.read = true;
        await notification.save();

        res.json({ message: `Application ${decision === 'ACCEPT' ? 'accepted' : 'rejected'} successfully` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Get notifications
const getNotifications = async (req, res) => {
    try {
        const notifs = await Notification.find({ userId: req.user._id }).sort({ createdAt: -1 }).limit(20);
        res.json(notifs);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Mark notification as read
const markNotificationRead = async (req, res) => {
    try {
        await Notification.findByIdAndUpdate(req.params.id, { read: true });
        res.json({ message: 'Read' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

module.exports = {
    registerRecruiter,
    authRecruiter,
    getRecruiterProfile,
    updateRecruiterProfile,
    googleSignInForRecruiter,
    githubSignInForRecruiter,
    checkRecruiterEmailExists,
    contactCandidate,
    receiveNotification,
    getNotifications,
    markNotificationRead,
    handleApplicationDecision
};

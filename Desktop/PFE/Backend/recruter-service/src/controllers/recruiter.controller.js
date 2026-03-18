const Recruiter = require('../models/recruiter');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d'
    });
};

// @desc    Register a new recruiter
// @route   POST /api/recruiter/register
// @access  Public
const registerRecruiter = async (req, res) => {
    try {
        const { email, password, entreprise, poste } = req.body;

        const recruiterExists = await Recruiter.findOne({ email });

        if (recruiterExists) {
            return res.status(400).json({ message: 'Recruiter already exists' });
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
                token: generateToken(recruiter._id)
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
                token: generateToken(recruiter._id)
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

module.exports = {
    registerRecruiter,
    authRecruiter,
    getRecruiterProfile,
    updateRecruiterProfile
};

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { registerRecruiter, authRecruiter, getRecruiterProfile, updateRecruiterProfile } = require('../controllers/recruiter.controller');
const { protect } = require('../middleware/auth-middleware');

// Multer Storage Configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public/uploads');
    },
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

const upload = multer({ storage });

// Public routes
router.post('/register', registerRecruiter);
router.post('/login', authRecruiter);

// Protected routes
router.get('/profile', protect, getRecruiterProfile);
router.put('/profile', protect, updateRecruiterProfile);

// Upload logo
router.post('/upload', protect, upload.single('logo'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ message: 'Please upload a file' });
    }
    const url = `http://127.0.0.1:5002/uploads/${req.file.filename}`;
    res.json({ url });
});

module.exports = router;

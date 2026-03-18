const express = require('express');
const multer = require('multer');
const router = express.Router();
const auth = require('../middleware/auth-middleware');
const { uploadCv } = require('../controllers/cv-controller');

const upload = multer({ storage: multer.memoryStorage() });

router.post('/upload', auth, upload.single('cv'), uploadCv);

module.exports = router;

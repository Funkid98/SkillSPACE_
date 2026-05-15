const express = require('express');
const multer = require('multer');
const router = express.Router();
const auth = require('../middleware/auth-middleware');
const { uploadCv, removeCv } = require('../controllers/cv-controller');

const fs = require('fs');
const path = require('path');

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir)
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9)
    cb(null, uniqueSuffix + '-' + file.originalname)
  }
})

const upload = multer({ storage: storage });

router.post('/upload', auth, upload.single('cv'), uploadCv);
router.delete('/', auth, removeCv);

module.exports = router;

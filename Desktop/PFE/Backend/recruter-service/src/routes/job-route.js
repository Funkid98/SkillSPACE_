const express = require('express');
const router = express.Router();
const { createJob, updateJob, deleteJob, getRecruiterJobs } = require('../controllers/job.controller');
const { protect } = require('../middleware/auth-middleware');

router.route('/')
    .post(protect, createJob)
    .get(protect, getRecruiterJobs);

router.route('/:id')
    .put(protect, updateJob)
    .delete(protect, deleteJob);

module.exports = router;

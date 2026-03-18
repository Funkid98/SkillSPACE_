const Job = require('../models/job');

// @desc    Create a new job
// @route   POST /api/job
// @access  Private
const createJob = async (req, res) => {
    try {
        const { title, description, company, location, salary, type, requirements } = req.body;

        const job = new Job({
            recruiter: req.user._id,
            title,
            description,
            company: company || req.user.entreprise,
            location,
            salary,
            type,
            requirements
        });

        const createdJob = await job.save();
        res.status(201).json(createdJob);
    } catch (error) {
        console.error('Create job error:', error);
        res.status(400).json({ message: error.message });
    }
};

// @desc    Update a job
// @route   PUT /api/job/:id
// @access  Private
const updateJob = async (req, res) => {
    try {
        const { title, description, company, location, salary, type, requirements } = req.body;

        const job = await Job.findById(req.params.id);

        if (job) {
            if (job.recruiter.toString() !== req.user._id.toString()) {
                return res.status(401).json({ message: 'User not authorized to update this job' });
            }

            job.title = title || job.title;
            job.description = description || job.description;
            job.company = company || job.company;
            job.location = location || job.location;
            job.salary = salary || job.salary;
            job.type = type || job.type;
            job.requirements = requirements || job.requirements;

            const updatedJob = await job.save();
            res.json(updatedJob);
        } else {
            res.status(404).json({ message: 'Job not found' });
        }
    } catch (error) {
        console.error('Update job error:', error);
        res.status(400).json({ message: error.message });
    }
};

// @desc    Delete a job
// @route   DELETE /api/job/:id
// @access  Private
const deleteJob = async (req, res) => {
    try {
        const job = await Job.findById(req.params.id);

        if (job) {
            if (job.recruiter.toString() !== req.user._id.toString()) {
                return res.status(401).json({ message: 'User not authorized to delete this job' });
            }

            await job.deleteOne();
            res.json({ message: 'Job removed' });
        } else {
            res.status(404).json({ message: 'Job not found' });
        }
    } catch (error) {
        console.error('Delete job error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all jobs for a recruiter
// @route   GET /api/job
// @access  Private
const getRecruiterJobs = async (req, res) => {
    try {
        const jobs = await Job.find({ recruiter: req.user._id });
        res.json(jobs);
    } catch (error) {
        console.error('Get jobs error:', error);
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createJob,
    updateJob,
    deleteJob,
    getRecruiterJobs
};

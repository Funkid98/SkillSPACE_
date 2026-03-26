const Offer = require('../models/offer.model');

// @desc    Create a new offer
// @route   POST /api/offers
// @access  Private
const createOffer = async (req, res) => {
    try {
        const { title, description, company, location, salary, type, requirements } = req.body;

        const offer = new Offer({
            recruiter: req.user._id,
            title,
            description,
            company: company || req.user.entreprise,
            location,
            salary,
            type,
            requirements
        });

        const createdOffer = await offer.save();
        res.status(201).json(createdOffer);
    } catch (error) {
        console.error('Create offer error:', error);
        res.status(400).json({ message: error.message });
    }
};

// @desc    Update an offer
// @route   PUT /api/offers/:id
// @access  Private
const updateOffer = async (req, res) => {
    try {
        const { title, description, company, location, salary, type, requirements } = req.body;

        const offer = await Offer.findById(req.params.id);

        if (offer) {
            if (offer.recruiter.toString() !== req.user._id.toString()) {
                return res.status(401).json({ message: 'User not authorized to update this offer' });
            }

            offer.title = title || offer.title;
            offer.description = description || offer.description;
            offer.company = company || offer.company;
            offer.location = location || offer.location;
            offer.salary = salary || offer.salary;
            offer.type = type || offer.type;
            offer.requirements = requirements || offer.requirements;

            const updatedOffer = await offer.save();
            res.json(updatedOffer);
        } else {
            res.status(404).json({ message: 'Offer not found' });
        }
    } catch (error) {
        console.error('Update offer error:', error);
        res.status(400).json({ message: error.message });
    }
};

// @desc    Delete an offer
// @route   DELETE /api/offers/:id
// @access  Private
const deleteOffer = async (req, res) => {
    try {
        const offer = await Offer.findById(req.params.id);

        if (offer) {
            if (offer.recruiter.toString() !== req.user._id.toString()) {
                return res.status(401).json({ message: 'User not authorized to delete this offer' });
            }

            await offer.deleteOne();
            res.json({ message: 'Offer removed' });
        } else {
            res.status(404).json({ message: 'Offer not found' });
        }
    } catch (error) {
        console.error('Delete offer error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all offers for a recruiter
// @route   GET /api/offers/my-offers
// @access  Private
const getRecruiterOffers = async (req, res) => {
    try {
        const offers = await Offer.find({ recruiter: req.user._id });
        res.json(offers);
    } catch (error) {
        console.error('Get offers error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get matching offers for a candidate
// @route   GET /api/offers/matches
// @access  Public
const getMatchingOffers = async (req, res) => {
    try {
        const { jobtitle } = req.query;
        if (!jobtitle) {
            return res.status(400).json({ message: 'jobtitle query parameter is required' });
        }

        const offers = await Offer.find({
            title: { $regex: jobtitle, $options: 'i' }
        });

        res.json(offers);
    } catch (error) {
        console.error('Get matches error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all offers
// @route   GET /api/offers
// @access  Public
const getOffers = async (req, res) => {
    try {
        const offers = await Offer.find({}).sort({ date: -1 });
        res.json(offers);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createOffer,
    updateOffer,
    deleteOffer,
    getRecruiterOffers,
    getMatchingOffers,
    getOffers
};

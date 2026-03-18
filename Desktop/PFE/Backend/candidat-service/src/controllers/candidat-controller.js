const User = require('../models/candidat')
const { hashPassword, verifyPassword, createToken, calculateCompletion } = require('../services/candidat-service')


// Register (for testing)
const register = async (req, res) => {
    try {
        const { email, password, prenom, nom } = req.body
        const hashedPassword = await hashPassword(password)
        const user = new User({ email, password: hashedPassword, prenom, nom })
        await user.save()
        const token = createToken(user._id)
        res.status(201).json({
            token,
            user: { _id: user._id, email: user.email, prenom: user.prenom, nom: user.nom, role: user.role }
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

// Login (for testing)
const login = async (req, res) => {
    try {
        const { email, password } = req.body
        const user = await User.findOne({ email })
        if (!user || !(await verifyPassword(password, user.password))) {
            return res.status(401).json({ error: 'Invalid credentials' })
        }
        const token = createToken(user._id)
        res.json({
            token,
            user: { _id: user._id, email: user.email, prenom: user.prenom, nom: user.nom, role: user.role }
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}


//Get Profile
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.userId).select('-password')
        if (!user) return res.status(404).json({ error: 'User not found' })
        res.json(user)
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

//Update Profile
const updateProfile = async (req, res) => {
    try {
        const updates = req.body
        const user = await User.findByIdAndUpdate(
            req.userId,
            { $set: updates },
            { new: true }
        ).select('-password')

        const completion = calculateCompletion(user)
        await User.findByIdAndUpdate(req.userId, { completion_percent: completion })

        res.json({ message: 'Profile updated', completion_percent: completion })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

module.exports = { register, login, getProfile, updateProfile }
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
            user: { _id: user._id, email: user.email, prenom: user.prenom, nom: user.nom, role: user.role, sector: user.sector }
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

// Login (for testing)
const login = async (req, res) => {
    try {
        const { email, password } = req.body
        console.log('Login attempt for:', email)
        const user = await User.findOne({ email })
        if (!user || !(await verifyPassword(password, user.password))) {
            return res.status(401).json({ error: 'Invalid credentials' })
        }
        console.log('User found in DB:', user.email, 'Sector:', user.sector)
        const token = createToken(user._id)
        res.json({
            token,
            user: { _id: user._id, email: user.email, prenom: user.prenom, nom: user.nom, role: user.role, sector: user.sector }
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}


//Get Profile
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.userId).select('-password').lean()
        if (!user) return res.status(404).json({ error: 'User not found' })

        // Auto-migrate old string skills to {name, percent} objects
        if (user.skills && user.skills.some(s => typeof s === 'string')) {
            user.skills = user.skills.map(s =>
                typeof s === 'string' ? { name: s, percent: 50 } : s
            )
            // Save migrated skills back to DB
            await User.findByIdAndUpdate(req.userId, { skills: user.skills })
        }

        res.json(user)
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

//Update Profile
const updateProfile = async (req, res) => {
    try {
        const updates = req.body
        console.log('Updating user:', req.userId, 'with:', updates)

        // Normalize skills: convert any plain strings to {name, percent} objects
        if (updates.skills && Array.isArray(updates.skills)) {
            updates.skills = updates.skills.map(s =>
                typeof s === 'string' ? { name: s, percent: 50 } : s
            )
        }

        const user = await User.findByIdAndUpdate(
            req.userId,
            { $set: updates },
            { new: true }
        ).select('-password').lean()

        const completion = calculateCompletion(user)
        await User.findByIdAndUpdate(req.userId, { completion_percent: completion })

        res.json({ message: 'Profile updated', completion_percent: completion })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

// Get recent candidates by sector
const getRecentCandidatesBySector = async (req, res) => {
    try {
        const { sector } = req.params
        const query = sector && sector !== 'all' ? { sector: new RegExp(sector, 'i') } : {}
        
        const candidates = await User.find(query)
            .select('prenom nom jobtitle sector localisation skills')
            .sort({ createdAt: -1 })
            .limit(10)
            .lean()
        
        // Map to a format expected by the frontend
        const formattedCandidates = candidates.map(c => ({
            _id: c._id,
            name: `${c.prenom} ${c.nom}`,
            role: c.jobtitle || 'Candidat',
            localisation: c.localisation || 'Non spécifiée',
            competences: (c.skills || []).map(s => typeof s === 'string' ? s : s.name),
            status: 'Nouveau',
            matchScore: 85, // Dummy score for now
            initials: `${c.prenom[0] || '?'}${c.nom[0] || '?'}`.toUpperCase()
        }))

        res.json(formattedCandidates)
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
}

module.exports = { register, login, getProfile, updateProfile, getRecentCandidatesBySector }
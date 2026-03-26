const express = require('express')
const router = express.Router()
const { register, login, getProfile, updateProfile, getRecentCandidatesBySector } = require('../controllers/candidat-controller')
const auth = require('../middleware/auth-middleware')


router.post('/register', register)
router.post('/login', login)


router.get('/me', auth, getProfile)
router.put('/me', auth, updateProfile)
router.get('/recent/:sector', getRecentCandidatesBySector)

router.get('/internal/:id', async (req, res) => {
    const User = require('../models/candidat')
    const user = await User.findById(req.params.id).select('-password')
    if (!user) return res.status(404).json({ error: 'Not found' })
    res.json(user)
})

module.exports = router
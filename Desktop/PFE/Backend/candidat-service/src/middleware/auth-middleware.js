const jwt = require('jsonwebtoken')

const authMiddleware = (req, res, next) => {
  try {
    let token;
    if (req.cookies && req.cookies.skillspace_token) {
      token = req.cookies.skillspace_token;
    }
    if (!token && req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      token = req.headers.authorization.replace('Bearer ', '');
    }

    if (!token) return res.status(401).json({ error: 'No token' })

    const payload = jwt.verify(token, process.env.JWT_SECRET)
    req.userId = payload.sub || payload.id
    next()
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' })
  }
}

module.exports = authMiddleware  
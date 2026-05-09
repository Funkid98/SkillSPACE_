const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
<<<<<<< HEAD
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');

        if (!token) {
            return res.status(401).json({ error: 'No token' });
        }

        const payload = jwt.verify(token, process.env.JWT_SECRET);

        req.userId = payload.sub || payload.id;

        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
=======
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({ error: 'No token' });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET);

    req.userId = payload.sub || payload.id;

    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
>>>>>>> 6c7e93a6e0c9423a047c6415031b919f4960dbb4
};

module.exports = authMiddleware;
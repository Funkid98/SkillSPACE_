const jwt = require('jsonwebtoken');
const Formateur = require('../models/formateurModel');

const protect = async (req, res, next) => {
  let token;

  if (req.cookies && req.cookies.skillspace_token) {
    token = req.cookies.skillspace_token;
  }
  
  if (!token && req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (token) {
    try {

      // Decode token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Extract user ID. In authController, we use both id and sub.
      const userId = decoded.id || decoded.sub;

      if (!userId) {
        return res.status(401).json({ message: 'Non autorisé, token invalide' });
      }

      // Find formateur
      req.user = await Formateur.findById(userId).select('-password');
      
      if (!req.user) {
        // This token is valid but doesn't belong to a Formateur
        return res.status(401).json({ message: 'Non autorisé, formateur introuvable' });
      }

      next();
    } catch (error) {
      console.error(error);
      return res.status(401).json({ message: 'Non autorisé, token échoué' });
    }
  } else {
    return res.status(401).json({ message: 'Non autorisé, pas de token' });
  }
};

module.exports = { protect };

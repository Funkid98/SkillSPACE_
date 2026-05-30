const jwt = require("jsonwebtoken");
const Recruiter = require("../models/recruiter");

const protect = async (req, res, next) => {
  let token;

  if (req.cookies && req.cookies.skillspace_token) {
    token = req.cookies.skillspace_token;
  }
  if (
    !token &&
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await Recruiter.findById(decoded.id).select("-password");
      next();
    } catch (error) {
      console.error(error);
      return res.status(401).json({ message: "Not authorized, token failed" });
    }
  } else {
    return res.status(401).json({ message: "Not authorized, no token" });
  }
};

module.exports = { protect };

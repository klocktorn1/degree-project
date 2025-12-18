const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const token = req.cookies.accessToken;

  if (!token) {
    return res.status(401).json({ message: 'Not authenticated' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Attach user info to request
    req.user = {
      id: decoded.id,
      email: decoded.email
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ tokenExpired: true });
    }

    return res.status(401).json({ message: 'Invalid token' });
  }
}


module.exports = requireAuth
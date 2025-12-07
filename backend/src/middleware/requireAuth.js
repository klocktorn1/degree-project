const jwt = require('jsonwebtoken')

function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).json({ message: "Missing or invalid Authoriziation header" })
    }
    const [scheme, token] = authHeader.split(' ');



    if (scheme !== 'Bearer' || !token ) {
        return res.status(401).json({ message: "Missing or invalid Authoriziation header" })
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded
        next();

    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ message: "Access token expired" })
        }
        return res.status(401).json({ message: 'Invalid token' })

    }
}

module.exports = requireAuth
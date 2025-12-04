const jwt = require('jsonwebtoken')

function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization;

    

    

    const [scheme, token] = authHeader.split(' ')
        console.log(token);


    if (scheme !== 'Bearer' || !token) {
        return res.status(401).json({ message: "Missing or invalid Authoriziation header" })
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = { id: decoded.id, email: decoded.email }
        next();

    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ message: "Access token expired" })
        }
        return res.status(401).json({ message: 'Invalid token' })

    }
}

module.exports = requireAuth
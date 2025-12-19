module.exports = function validateRegisterUser(req, res, next) {
    const { email, firstname, lastname, password } = req.body;
    const missingFields = [];

    if (!email) missingFields.push("email");
    if (!firstname) missingFields.push("firstname");
    if (!lastname) missingFields.push("lastname");
    if (!password) missingFields.push("password");

    if (missingFields.length > 0) {
        return res.status(400).json({
            error: `Missing required fields: ${missingFields.join(", ")}`
        });
    }

    next();
};

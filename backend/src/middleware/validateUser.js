module.exports = function validateExerciseResult(req, res, next) {
    const { username, email, firstname, lastname, password_hash } = req.body;
    const missingFields = [];

    if (!username) missingFields.push("username");
    if (!email) missingFields.push("email");
    if (!firstname) missingFields.push("firstname");
    if (!lastname) missingFields.push("lastname");
    if (!password_hash) missingFields.push("password_hash");

    if (missingFields.length > 0) {
        return res.status(400).json({
            error: `Missing required fields: ${missingFields.join(", ")}`
        });
    }

    next();
};

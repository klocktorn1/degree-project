module.exports = function validateExerciseResult(req, res, next) {
    const { name, description } = req.body;
    const missingFields = [];

    if (!name) missingFields.push("name");
    if (!description) missingFields.push("description");

    if (missingFields.length > 0) {
        return res.status(400).json({
            error: `Missing required fields: ${missingFields.join(", ")}`
        });
    }

    next();
};

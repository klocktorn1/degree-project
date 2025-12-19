module.exports = function validateCompletedExercises(req, res, next) {
    const { sub_exercise_id, difficulty } = req.body;
    const missingFields = [];

    if (!sub_exercise_id) missingFields.push("sub_exercise_id");
    if (!difficulty) missingFields.push("difficulty");

    if (missingFields.length > 0) {
        return res.status(400).json({
            error: `Missing required fields: ${missingFields.join(", ")}`
        });
    }

    next();
};

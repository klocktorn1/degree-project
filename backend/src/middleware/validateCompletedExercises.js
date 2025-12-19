module.exports = function validateCompletedExercises(req, res, next) {
    const { user_id, exercise_id, difficulty, completed_at } = req.body;
    const missingFields = [];

    if (!user_id) missingFields.push("user_id");
    if (!exercise_id) missingFields.push("exercise_id");
    if (!difficulty) missingFields.push("difficulty");
    if (!completed_at) missingFields.push("completed_at");

    if (missingFields.length > 0) {
        return res.status(400).json({
            error: `Missing required fields: ${missingFields.join(", ")}`
        });
    }

    next();
};

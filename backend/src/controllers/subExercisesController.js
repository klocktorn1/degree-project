const db = require('../db/connection');

const getAllSubExercises = async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM sub_exercises');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}
const getSubExerciseById = async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM sub_exercises WHERE id = ?', [req.params.id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Sub exercise not found' });
        }
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

const getSubExercisesByExerciseId = async (req, res) => {

    try {
        const [rows] = await db.query('SELECT * FROM sub_exercises WHERE exercise_id = ?', [req.params.id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: `sub_exercises with exercise-id ${req.params.id} not found` });
        }
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// const createSubExercise = async (req, res) => {
//     try {
//         const { name, description } = req.body;
//         const [result] = await db.query(
//             'INSERT INTO sub_exercises (name, description) VALUES (?, ?)',
//             [name, description]
//         );
//         res.json({ id: result.insertId });
//     } catch (err) {
//         res.status(500).json({ error: err.message });
//     }
// };
// const deleteSubExercise = async (req, res) => {
//     try {
//         const [result] = await db.query(
//             'DELETE FROM sub_exercises WHERE id = ?',
//             [req.params.id]
//         );
//         if (result.affectedRows === 0) {
//             return res.status(404).json({ message: "Exercise not found" });

//         } else {
//             return res.json({ message: "Successfuly deleted exercise" });
//         }
//     } catch (err) {
//         res.status(500).json({ error: err.message });
//     }
// };



module.exports = {
    getAllSubExercises,
    getSubExercisesByExerciseId,
    getSubExerciseById,
};

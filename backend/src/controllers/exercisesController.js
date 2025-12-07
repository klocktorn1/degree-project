const db = require('../db/connection');

const getAllExercises = async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM exercises');
        res.json({ exercises: rows });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}
const getExerciseById = async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM exercises WHERE id = ?', [req.params.id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Exercise not found' });
        }
        res.json({ exercise: rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

const createExercise = async (req, res) => {
    try {
        const { name, description } = req.body;
        const [result] = await db.query(
            'INSERT INTO exercises (name, description) VALUES (?, ?)',
            [name, description]
        );
        res.json({ id: result.insertId });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
const deleteExercise = async (req, res) => {
    try {
        const [result] = await db.query(
            'DELETE FROM exercises WHERE id = ?',
            [req.params.id]
        );
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: "Exercise not found" });

        } else {
            return res.json({ message: "Successfuly deleted exercise" });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};



module.exports = {
    getAllExercises,
    getExerciseById,
    createExercise,
    deleteExercise
};

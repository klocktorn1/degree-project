const db = require('../db/connection'); // mysql2 pool

// Get all exercise results
const getAllExerciseResults = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM exercise_results');
    res.json({ exercise_results: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get exercise result by id
const getExerciseResultsById = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM exercise_results WHERE id = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Exercise result not found' });
    }

    res.json({ exercise_results: rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Create a new exercise result
const createExerciseResults = async (req, res) => {
  const { user_id, exercise_id, score, completed_at } = req.body;

  if (user_id === undefined || exercise_id === undefined || score === undefined) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const [result] = await db.query(
      'INSERT INTO exercise_results (user_id, exercise_id, score, completed_at) VALUES (?, ?, ?, ?)',
      [user_id, exercise_id, score, completed_at || null]
    );

    res.json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  getAllExerciseResults,
  getExerciseResultsById,
  createExerciseResults,
};


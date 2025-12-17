const db = require('../db/connection'); // mysql2 pool

// Get all exercise results
const getAllExerciseResults = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM exercise_results');
    res.json({ exercise_results: rows });
  } catch (err) {
    res.status(500).json({ error: `getAllExerciseResults inside exerciseResultsContainer: ${err.message}` })
  }
};

// Get exercise result by user id
const getExerciseResultsById = async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM exercise_results WHERE user_id = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Exercise result not found' });
    }

    res.json({ exercise_results: rows });
  } catch (err) {
    res.status(500).json({ error: `getExerciseResultsById inside exerciseResultsContainer: ${err.message}` })
  }
};

// Create a new exercise result
const createExerciseResults = async (req, res) => {
  const { user_id, exercise_id, score, completed_at } = req.body;
  const authorizedUserId = req.user.id

  if (authorizedUserId !== user_id) {
    return res.status(401).json({ message: "Forbidden: No Access" })
  }

  try {
    const [result] = await db.query(
      'INSERT INTO exercise_results (user_id, exercise_id, score, completed_at) VALUES (?, ?, ?, ?)',
      [user_id, exercise_id, score, completed_at || null]
    );

    res.json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: `createExerciseResults inside exerciseResultsContainer: ${err.message}` })
  }
};

const deleteExerciseResults = async (req, res) => {
  const authorizedUserId = req.user.id
  const { id } = req.params

  try {
    const [rows] = await db.query(
      'DELETE FROM exercise_results WHERE id = ? AND user_id = ?',
      [id, authorizedUserId]
    );
    if (rows.affectedRows === 0) {
      return res.status(404).json({ message: "Exercise result not found or access denied" });
    } else {
      return res.json({ message: "Exercise result successfully deleted" })
    }

  } catch (err) {
    res.status(500).json({ error: `deleteExerciseResults inside exerciseResultsContainer: ${err.message}` })
  }

}

module.exports = {
  getAllExerciseResults,
  getExerciseResultsById,
  createExerciseResults,
  deleteExerciseResults
};


const db = require('../db/connection'); // mysql2 pool

const getAllCompletedExercisesByUserId = async (req, res) => {
  const userId = req.user.id
  try {
    const [rows] = await db.query(
      'SELECT * FROM completed_exercises WHERE user_id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Completed exercises not found' });
    }

    res.json({ completed_exercises: rows });
  } catch (err) {
    res.status(500).json({ error: `getAllCompletedExercises inside completedExercisesController: ${err.message}` })
  }
};



const getCompletedExercise = async (req, res) => {
  const userId = req.user.id
  try {
    const [rows] = await db.query(
      'SELECT * FROM completed_exercises WHERE user_id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Completed exercise not found' });
    }

    return res.json({ completed_exercise: rows[0] });
  } catch (err) {
    res.status(500).json({ error: `getCompletedExercise inside completedExercisesController: ${err.message}` })
  }
};

const createCompletedExercises = async (req, res) => {
  const { sub_exercise_id, difficulty, shuffled } = req.body;
  const userId = req.user.id

  

  try {
    const [result] = await db.query(
      'INSERT INTO completed_exercises (user_id, sub_exercise_id, difficulty, shuffled) VALUES (?, ?, ?, ?)',
      [userId, sub_exercise_id, difficulty, shuffled]
    );

    return res.json({ ok: true, message: `Completed entry inserted` });
  } catch (err) {
    res.status(500).json({ error: `createCompletedExercises inside completedExercisesController: ${err.message}` })
  }
};

const deleteCompletedExercise = async (req, res) => {
  const userId = req.user.id
  const { id } = req.params

  try {
    const [rows] = await db.query(
      'DELETE FROM completed_exercises WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    if (rows.affectedRows === 0) {
      return res.status(404).json({ message: "Completed exercise not found or access denied" });
    } else {
      return res.json({ message: "Completed exercise successfully deleted" })
    }

  } catch (err) {
    res.status(500).json({ error: `deleteCompletedExercise inside completedExercisesController: ${err.message}` })
  }

}

module.exports = {
  getAllCompletedExercisesByUserId,
  getCompletedExercise,
  createCompletedExercises,
  deleteCompletedExercise
};


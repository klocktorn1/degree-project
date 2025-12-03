const db = require('../db/connection');

const getAllUsers = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM users');
    req.json({ users: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
const getUserById = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ user: rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const createUser = async (req, res) => {
  const { username, email, firstname, lastname, password_hash } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO users (username, email, firstname, lastname, password_hash) VALUES (?, ?, ?, ?, ?)',
      [username, email, firstname, lastname, password_hash]
    );
    res.json({ id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  createUser,
};

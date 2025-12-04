const db = require('../db/connection');
const bcrypt = require('bcrypt');


const getAllUsers = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM users');
    res.json({ users: rows });
  } catch (err) {
    res.status(500).json({ error: `getAllUsers in usersController: ${err.message}` });
  }
};
const getUserById = async (req, res) => {
  try {
    const [row] = await db.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
    if (row.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ user: row[0] });
  } catch (err) {
    res.status(500).json({ error: `getUserById in usersController: ${err.message}` });
  }
};



const updateUser = async (req, res) => {
  const { id } = req.params
  const { username, email, firstname, lastname, password } = req.body;

  const fields = {}

  if (username) fields.username = username;
  if (email) fields.email = email;
  if (firstname) fields.firstname = firstname;
  if (lastname) fields.lastname = lastname;
  if (password) {

    const saltRounds = 12;
    const password_hash = await bcrypt.hash(password, saltRounds);
    fields.password_hash = password_hash;

  }
  try {
    const [result] = await db.query(
      'UPDATE users SET ? WHERE id = ?',
      [fields, id]
    );

    if (result.affectedRows === 0) {
      res.status(404).json({ error: "User not found" })
    }
    res.json({ message: "User updated successfully" })
    console.log(fields);
  } catch (err) {
    res.status(500).json({ error: `updateUser in usersController: ${err.message}` });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  updateUser,
};

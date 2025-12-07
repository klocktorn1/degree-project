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

  const requestedId = parseInt(req.params.id); // id in the URL
  const authenticatedId = req.user.id; // id from JWT payload

  if (requestedId !== authenticatedId) {
    res.status(403).json({ message: "Forbidden: Access denied" })
  }

  try {
    const [row] = await db.query('SELECT * FROM users WHERE id = ?', [requestedId]);
    if (row.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const { username, email, firstname, lastname, created_at } = row[0]
    res.json({ user: { username, email, firstname, lastname, created_at } });
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
      return res.status(404).json({ error: "User not found" })
    }
    return res.json({ message: "User updated successfully" })
  } catch (err) {
    res.status(500).json({ error: `updateUser in usersController: ${err.message}` });
  }
};


const deleteUser = async (req, res) => {
  const authorizedUserId = req.user.id
  const id = Number(req.params.id)


  if (authorizedUserId !== id) {

    return res.status(404).json({ message: "Forbidden: No Access" })
  } else {
    
    try {
      const result = db.query('DELETE FROM users WHERE id = ?', [id])
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: "User not found" })
      } else {
        return res.json({ error: "User successfully deleted" })
      }

    } catch (err) {
      return res.status(500).json({ error: `deleteUser in usersController: ${err.message}` });

    }
  }
}

module.exports = {
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser
};

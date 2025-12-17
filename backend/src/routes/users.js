const express = require('express');
const router = express.Router();
const { getAllUsers, getUser, updateUser, deleteUser } = require('../controllers/usersController');
const validateUpdateUser = require('../middleware/validateUpdateUser');

// Routes
router.get('/', getAllUsers);
router.get('/me', getUser);
router.patch('/:id', validateUpdateUser, updateUser);
router.delete('/:id', deleteUser)

module.exports = router;

const express = require('express');
const router = express.Router();
const { getAllUsers, getUserById, createUser, updateUser } = require('../controllers/usersController');
const validateUpdateUser = require('../middleware/validateUpdateUser');

// Routes
router.get('/', getAllUsers);
router.get('/:id', getUserById);
router.patch('/:id', validateUpdateUser, updateUser);

module.exports = router;

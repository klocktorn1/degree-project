const express = require('express');
const router = express.Router();
const { loginUser, registerUser, refreshToken, forgotPassword, resetPassword } = require('../controllers/authController');
const validateRegisterUser = require('../middleware/validateRegisterUser')


// Routes
router.post('/login', loginUser);
router.post('/register', validateRegisterUser, registerUser);
router.post('/refresh', refreshToken)
router.post('/forgot-password', forgotPassword)
router.post('/forgot-password/:token', resetPassword)

module.exports = router;

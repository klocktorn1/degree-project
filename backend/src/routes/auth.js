const express = require('express');
const router = express.Router();
const { loginUser, logoutUser, registerUser, refreshToken, forgotPassword, resetPassword, debug } = require('../controllers/authController');
const validateRegisterUser = require('../middleware/validateRegisterUser')


// Routes
router.post('/login', loginUser);
router.post('/logout', logoutUser);
router.post('/register', validateRegisterUser, registerUser);
router.post('/refresh', refreshToken)
router.post('/forgot-password', forgotPassword)
router.post('/forgot-password/:id/:token', resetPassword)
router.get('/debug', debug)

module.exports = router;

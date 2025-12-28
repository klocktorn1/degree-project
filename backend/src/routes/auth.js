const express = require('express');
const router = express.Router();
const { loginUser, logoutUser, registerUser, refreshToken, forgotPassword, resetPassword, githubCallback, googleCallback } = require('../controllers/authController');


// Routes
router.post('/login', loginUser);
router.post('/logout', logoutUser);
router.post('/register', registerUser);
router.post('/refresh', refreshToken)
router.post('/forgot-password', forgotPassword)
router.post('/forgot-password/:id/:token', resetPassword)
router.get('/google/callback', googleCallback)
router.get('/github/callback', githubCallback)

module.exports = router;

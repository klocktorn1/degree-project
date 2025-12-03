const express = require('express');
const router = express.Router();
const validateExercise = require('../middleware/validateExercise');
const { getAllExercises, createExercise } = require('../controllers/exercisesController');

// Routes
router.get('/', getAllExercises);
router.post('/', validateExercise, createExercise);

module.exports = router;
